#!/bin/bash
set -u
set -o pipefail
# set -uo pipefail
# set -euo pipefail

# Copyright (C) 2025 José Enrique Vilca Campana
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# ==============================================================================================
# GLOBAL VARIABLES
# ==============================================================================================

program_name="CP Stress Tester"
my_exec=""
brute_exec=""

problem_file=""

problem=""
my_sol=""
brute_sol=""

final_my_sol_file=""
final_brute_sol_file=""
final_problem_file=""

my_sol_field=""
brute_sol_field=""
problem_field=""

result=""

next_interface=0
valid_input=0

problem_file_already_exists=0

# ==============================================================================================
# GLOBAL CONSTANTS
# ==============================================================================================

end_program=255
form_interface=0
form_help_interface=1
form_error_interface=2
RNG_template_interface=3
RNG_template_confirmation_interface=4
editor_interface=5
editor_confirmation_interface=6

declare -A form_error_types=(
	[inexistant_file]=2
	[problem_already_exists]=3
	[empty_all]=4
	[empty_problem]=5
	[empty_solution]=6
	[empty_brute_solution]=7
	[invalid_solution]=8
	[invalid_brute]=9
	[invalid_problem]=10
	[infered_solution_not_found]=11
	[infered_brute_not_found]=12
	[problem_file_inexistant]=13
	[problem_file_already_exists]=14
	[sol_not_inferenciable]=15
	[brute_not_inferenciable]=16
	[inexistant_solution_file]=17
	[inexistant_brute_file]=18
)

form_errors=()

form_error_type__not_inferenciable=1
form_error_type__empty_fields=2
form_error_type__inexistant_file=3
form_error_type__problem_already_exists=4
# name value or RNG_<name>.py/RNG_<problem>.py already exists

form_error_type=0

: "${DIALOG=dialog}"

: "${DIALOG_OK=0}"
: "${DIALOG_CANCEL=1}"
: "${DIALOG_HELP=2}"
: "${DIALOG_EXTRA=3}"
: "${DIALOG_ITEM_HELP=4}"
: "${DIALOG_ESC=255}"

: "${SIG_NONE=0}"
: "${SIG_HUP=1}"
: "${SIG_INT=2}"
: "${SIG_QUIT=3}"
: "${SIG_KILL=9}"
: "${SIG_TERM=15}"

F_EMPTY=1         # 000001
F_FILE_EXISTS=2   # 000010
F_HAS_BASENAME=4  # 000100
F_HAS_EXTENSION=8 # 001000
F_IS_INVALID=16   # 010000
F_INFERABLE=32    # 100000

# ==============================================================================================
# END GLOBAL SCOPE
# ==============================================================================================

debugging=1
dlog() {
	# The purpose of dlog is ...
	file="./debug.log"
	if [[ ${debugging} == 1 ]]; then
		echo "$@" >>${file}
	fi
}

decho() {
	if [[ ${debugging} == 1 ]]; then
		echo "$@"
	fi
}

# ==============================================================================================
# END DEBUG FUNCTIONS
# ==============================================================================================

# Basic classifier required by your other functions
# Returns: 0=Invalid, 1=Basename only, 2=Extension only, 3=Both
classify_filename() {
	local fn="$1"
	local mask=0

	# Check for invalid characters or empty
	# Note: This currently forbids paths with folders like "dir/sol.py" due to the "/" check
	if [[ -z $fn || $fn == *"/"* ]]; then
		echo 0
		return
	fi

	# Check for Basename (anything before the last dot, or no dot)
	if [[ $fn == *.* && ${fn%.*} != "" ]]; then
		((mask |= 1))
	elif [[ $fn != *.* ]]; then
		((mask |= 1))
	fi

	# Check for Extension (must have a dot and text after it)
	if [[ $fn == *.* && ${fn##*.} != "" ]]; then
		((mask |= 2))
	fi

	echo "$mask"
}

has_basename() {
	local value="$1" # CHANGED: Accept value directly
	local true_ret="${2:-1}"
	local category
	category=$(classify_filename "$value")

	if ((category & 1)); then
		return "$true_ret"
	else
		return 0
	fi
}

has_extension() {
	local value="$1" # CHANGED: Accept value directly
	local true_ret="${2:-1}"
	local category
	category=$(classify_filename "$value")

	if ((category & 2)); then
		return "$true_ret"
	else
		return 0
	fi
}

is_invalid() {
	local value="$1" # CHANGED: Accept value directly
	local true_ret="${2:-1}"
	local category
	category=$(classify_filename "$value")

	if ((category == 0)); then
		return "$true_ret"
	else
		return 0
	fi
}

is_empty() {
	local value="$1" # CHANGED: Accept value directly
	local true_ret="${2:-1}"

	if [[ -z $value ]]; then
		return "$true_ret"
	else
		return 0
	fi
}

file_exists() {
	local value="$1" # CHANGED: Accept value directly
	local true_ret="${2:-1}"

	if [[ -f $value ]]; then
		return "$true_ret"
	else
		return 0
	fi
}

copy_assoc_array() {
	local src_name="$1"
	local dst_name="$2"
	# Use namerefs for indirect access
	declare -n src="$src_name"
	declare -n dst="$dst_name"

	# Iterate keys of source
	for key in "${!src[@]}"; do
		dst["$key"]="${src[$key]}"
	done
}

# Helper to remove _brute suffix if present
strip_brute_suffix() {
	local str="$1"
	# Removes _brute from the end of the string
	echo "${str%_brute}"
}

# ==============================================================================================
# END HELPER FUNCTIONS
# ==============================================================================================

print() {
	echo ${reset}
	for param in "$@"; do
		echo -n -e "${param}"
		echo ${reset}
	done
}

println() {
	echo ${reset}
	for param in "$@"; do
		echo -n -e "${param}"
	done
	echo ${reset}
	echo
}

check_file_exists() {
	if [[ -f $1 ]]; then
		return 1 # the file exists
	else
		return 0
	fi
}

calculate_form_flags() {
	local arr_name="$1"
	shift
	# 1. Capture Inputs
	local _my_sol="$1"
	local _brute_sol="$2"
	local _problem="$3"

	# 2. Store originals to detect changes later (for is_inferable)
	local orig_my_sol="$_my_sol"
	local orig_brute_sol="$_brute_sol"
	local orig_problem="$_problem"

	# =========================================================
	# PHASE A: INFERENCE LOGIC (String Manipulation)
	# =========================================================
	# We use direct string checks here for logic, not the helper functions,
	# to keep the logic flow linear and clean.

	# -- Analyze Raw Components --
	local my_base="${_my_sol%.*}"
	local my_ext="${_my_sol##*.}"
	local brute_base="${_brute_sol%.*}"
	local brute_ext="${_brute_sol##*.}"

	# Check what we actually have (Simple booleans for logic)
	local has_my_base=0
	[[ $_my_sol != *.* || -n $my_base ]] && has_my_base=1
	local has_my_ext=0
	[[ $_my_sol == *.* && -n $my_ext ]] && has_my_ext=1
	local has_br_base=0
	[[ $_brute_sol != *.* || -n $brute_base ]] && has_br_base=1
	local has_br_ext=0
	[[ $_brute_sol == *.* && -n $brute_ext ]] && has_br_ext=1
	dlog "has_br_base: $has_br_base"
	dlog "has_br_ext:  $has_br_ext"

	# -- 1. Fix My Sol --
	if [[ -n $_my_sol && $_my_sol != */* ]]; then
		# If Base only, try to steal extension from brute
		if ((has_my_base && !has_my_ext && has_br_ext)); then
			_my_sol="${_my_sol}.${brute_ext}"
		fi
		# If Extension only (starts with dot), try to steal base from brute
		if ((!has_my_base && has_my_ext && has_br_base)); then
			local clean_base
			clean_base="$(strip_brute_suffix "$brute_base")"
			[[ -n $clean_base ]] && _my_sol="${clean_base}.${my_ext}"
		fi
	fi

	# -- 2. Fix Brute Sol --
	# Update my_sol info in case it changed
	my_ext="${_my_sol##*.}"
	[[ $_my_sol == *.* && -n $my_ext ]] && has_my_ext=1 || has_my_ext=0

	if [[ -z $_brute_sol || $_brute_sol == */* ]]; then
		# Brute empty or invalid: create from My Sol
		has_basename "${_my_sol}"
		if (( $? )); then # If my_sol has base (flag returned)
			local new_base="${_my_sol%.*}_brute"
			if ((has_my_ext)); then
				_brute_sol="${new_base}.${my_ext}"
			else
				_brute_sol="${new_base}"
			fi
		fi
	else
		# Brute exists but might be partial
		if ((has_br_base && !has_br_ext && has_my_ext)); then
			_brute_sol="${_brute_sol}.${my_ext}"
		fi
		if ((!has_br_base && has_br_ext)); then
			has_basename "${_my_sol}"
			if (( $? )); then
				# Have the same extension?
				# if different, check with and without suffix _brute.
				local base="${_my_sol%.*}"
				local with="${base}_brute.${brute_ext}"
				local without="${base}.${brute_ext}"
				file_exists "${with}"
				local _with_suffix=$?
				file_exists "${without}"
				local _without_suffix=$?
				if [[ "${brute_ext}" != "${my_ext}" ]]; then
					# try with and without suffix *_brute.*
					if (( _with_suffix )); then
						_brute_sol="${base}_brute.${brute_ext}";
					elif (( _without_suffix )); then
						_brute_sol="${base}.${brute_ext}";
					else
						_brute_sol="no_infered_brute_file_found.error";
					fi
				# if same, check with suffix _brute.
				else
					if (( _with_suffix )); then
						_brute_sol="${base}_brute.${brute_ext}";
					else
						_brute_sol="no_infered_brute_file_found.error";
					fi
				fi

			fi
		fi
	fi

	# -- 3. Fix Problem --
	if [[ -z $_problem ]]; then
		# Try my_sol first
		has_basename $_my_sol
		local chk_my_base=$?
		if ((chk_my_base)); then
			_problem="${_my_sol%.*}"
		else
			# Try brute_sol
			has_basename $_brute_sol
			local chk_br_base=$?
			if ((chk_br_base)); then
				local raw="${_brute_sol%.*}"
				_problem="$(strip_brute_suffix "$raw")"
			fi
		fi
	fi

	# =========================================================
	# PHASE B: UPDATE GLOBALS
	# =========================================================

	final_my_sol_file="$_my_sol"
	final_brute_sol_file="$_brute_sol"
	final_problem_file="$_problem"

	# =========================================================
	# PHASE C: CALCULATE FLAGS
	# =========================================================

	# We use a loop or internal function to calculate flags for the 3 files
	# This ensures we don't repeat the flag logic 3 times.

	# Usage: get_flags "GLOBAL_VAR_NAME" "ORIGINAL_VALUE" "IS_PROBLEM_FILE_BOOL"
	_get_flags() {
		local var_name="$1"
		local orig_val="$2"
		local is_prob="$3"
		local flags=0
		local current_val="${!var_name}"

		# 1. Empty?
		is_empty "$var_name" $F_EMPTY
		flags=$((flags | $?))

		# 2. Exists?
		# IMPORTANT: file_exists expects a variable name.
		# We must create a temporary variable with the ACTUAL path to check.
		local path_check="$current_val"
		if [[ $is_prob == "1" && -n $current_val ]]; then
			path_check="RNG_${current_val}.py"
		fi

		# Pass the VALUE to the helper
		file_exists "$path_check" $F_FILE_EXISTS
		flags=$((flags | $?))

		# 3. Syntax checks
		has_basename "$current_val" $F_HAS_BASENAME
		flags=$((flags | $?))
		has_extension "$current_val" $F_HAS_EXTENSION
		flags=$((flags | $?))
		is_invalid "$current_val" $F_IS_INVALID
		flags=$((flags | $?))

		# 4. Inferable? (If current value differs from original)
		if [[ $current_val != "$orig_val" ]]; then
			flags=$((flags | F_INFERABLE))
		fi

		echo "$flags"
	}

	local f_my
	f_my=$(_get_flags "final_my_sol_file" "$orig_my_sol" "0")

	local f_brute
	f_brute=$(_get_flags "final_brute_sol_file" "$orig_brute_sol" "0")

	local f_prob
	f_prob=$(_get_flags "final_problem_file" "$orig_problem" "1")

	# =========================================================
	# PHASE D: RETURN
	# =========================================================

	# Initialize array if not already done
	eval "$arr_name=()"
	eval "$arr_name=($f_my $f_brute $f_prob)"
}

are_there_errors_in_form() {
	# return 0 -> false, no errors found
	# return 1 -> true, errors found
	local flags_array_name="$1"
	declare -n flags_ref="$flags_array_name"

	local f_my="${flags_ref[0]}"
	local f_brute="${flags_ref[1]}"
	local f_prob="${flags_ref[2]}"

	local MASK_FULL_FILE=$((F_HAS_BASENAME | F_HAS_EXTENSION))
	local MASK_BASENAME_ONLY=$((F_HAS_BASENAME))

	form_errors=()

	# --- CHECK 1: GLOBAL EMPTY ---
	if (((f_my & F_EMPTY) && (f_brute & F_EMPTY) && (f_prob & F_EMPTY))); then
		form_errors+=("empty_all")
		return
	fi

	# --- CHECK 2: INDIVIDUAL EMPTINESS ---
	# If it is Empty, it wasn't inferable (because inference removes the empty flag)
	if ((f_brute & F_EMPTY)); then form_errors+=("empty_brute_solution"); fi
	if ((f_my & F_EMPTY)); then form_errors+=("empty_solution"); fi
	if ((f_prob & F_EMPTY)); then form_errors+=("empty_problem"); fi

	# --- CHECK 3: SYNTAX / INFERENCE FAILURE ---
	# If NOT empty, but lacks Base/Ext or is Invalid -> It's "Not Inferable"
	# We check each file. If it has issues, we add the error.

	# Logic: It is NOT empty, BUT (Is Invalid OR Missing Base OR Missing Ext)
	check_syntax() {
		local flags="$1"
		local err_name="$2"
		local required_mask="$3" # Passed dynamically

		if ((flags & F_EMPTY)); then return; fi

		# FIX 2: Check against the specific mask provided
		if (((flags & F_IS_INVALID) || (flags & required_mask) != required_mask)); then
			form_errors+=("${err_name}")
		fi
	}

	check_syntax "$f_my" ${form_error_types["invalid_solution"]} "${MASK_FULL_FILE}"
	check_syntax "$f_brute" ${form_error_types["invalid_brute"]} "${MASK_FULL_FILE}"
	check_syntax "$f_prob" ${form_error_types["invalid_problem"]} "${MASK_BASENAME_ONLY}"

	# --- CHECK 4: FILE EXISTENCE (The "Disk" Check) ---

	# Logic for Solutions: They MUST exist.
	# If valid syntax, but file doesn't exist -> error
	if (((f_my & MASK_FULL_FILE) == MASK_FULL_FILE)); then
		if (((f_my & F_FILE_EXISTS) == 0)); then
			if ((f_my & F_INFERABLE)); then
				form_errors+=("infered_solution_not_found")
			else
				form_errors+=("inexistant_solution_file")
				dlog f_my
			fi
		fi
	fi

	if (((f_brute & MASK_FULL_FILE) == MASK_FULL_FILE)); then
		if (((f_brute & F_FILE_EXISTS) == 0)); then
			if ((f_brute & F_INFERABLE)); then
				form_errors+=("infered_brute_not_found")
				dlog "f_brute: $f_brute"
				dlog "final_brute_sol_file: $final_brute_sol_file"
				dlog "brute_sol_field: $brute_sol_field"
			else
				form_errors+=("inexistant_brute_file")
			fi
		fi
	fi

	# Problem Logic:
	# If checking for "problem already exists" (Creation mode):
	if (((f_prob & MASK_BASENAME_ONLY) == MASK_BASENAME_ONLY)); then
		if (((f_prob & F_FILE_EXISTS) == 1)); then # Note: F_EXISTS logic handled appending RNG_ and .py internally
			form_errors+=("problem_file_already_exists")
		fi
	fi
}

validate_form_input() {
	# return 0: invalid input,
	# return 1: valid input
	sol_brute_problem_flags=()
	calculate_form_flags sol_brute_problem_flags "${my_sol_field}" "${brute_sol_field}" "${problem_field}"
	are_there_errors_in_form sol_brute_problem_flags
	if ((${#form_errors[@]} == 0)); then
		echo "we have no errors"
		return 1
	else
		echo "we have errors"
		return 0
	fi
	# return $?
}

show_form_errors() {
	declare -A errors

	copy_assoc_array form_error_types errors
	local error_message="The following errors were found:\n\n"
	height=10
	width=70

	# final_my_sol_file
	# final_brute_sol_file
	# final_problem_file
	local _f_my_sol=1
	local _f_brute_sol=2
	local _f_problem=4
	local show_files=0
	local show_fields=0

	for e in "${form_errors[@]}"; do
		error_message+="--"
		# case ${errors[$e]} in
		case ${e} in
		${errors[inexistant_solution_file]})
			error_message+="inexistant solution file.\n"
			((show_files |= _f_my_sol))
			((show_fields |= _f_my_sol))
			;;
		${errors[inexistant_brute_file]})
			error_message+="inexistant brute file.\n"
			((show_files |= _f_brute_sol))
			((show_fields |= _f_brute_sol))
			;;
		${errors[empty_all]})
			error_message+="All fields are empty, you must fill at least 1 field.\n"
			;;
		${errors[empty_problem]})
			error_message+="empty problem.\n"
			((show_fields |= _f_problem))
			;;
		${errors[empty_solution]})
			error_message+="empty solution.\n"
			((show_fields |= _f_my_sol))
			;;
		${errors[empty_brute_solution]})
			error_message+="empty brute solution.\n"
			((show_fields |= _f_brute_sol))
			;;
		${errors[invalid_solution]})
			error_message+="invalid solution.\n"
			((show_fields |= _f_my_sol))
			;;
		${errors[invalid_brute]})
			error_message+="invalid brute.\n"
			((show_fields |= _f_brute_sol))
			;;
		${errors[invalid_problem]})
			error_message+="invalid problem.\n"
			((show_fields |= _f_problem))
			;;
		${errors[infered_solution_not_found]})
			error_message+="infered solution not found.\n"
			((show_files |= _f_my_sol))
			((show_fields |= _f_brute_sol))
			;;
		${errors[infered_brute_not_found]})
			error_message+="infered brute not found.\n"
			((show_files |= _f_brute_sol))
			((show_fields |= _f_my_sol))
			;;
		${errors[problem_file_already_exists]})
			error_message+="problem file already exists.\n"
			((show_files |= _f_problem))
			((show_fields |= _f_problem))
			;;
		${errors[sol_not_inferenciable]})
			error_message+="sol not inferenciable.\n"
			((show_files |= _f_brute_sol_))
			((show_fields |= _f_brute_sol))
			;;
		${errors[brute_not_inferenciable]})
			error_message+="brute not inferenciable.\n"
			((show_files |= _f_my_sol))
			((show_fields |= _f_my_sol))
			;;
		*)
			error_message+="error code: ${e}.\n Unknown error type.\n"
			;;
		esac
		((height+=1))
	done

	if ((show_files != 0)); then
		error_message+="\nSuggested files:\n"
		((height+=1))
		if ((show_files & _f_my_sol)); then
			error_message+="--Solution file : ${final_my_sol_file}\n"
			((height+=1))
		fi
		if ((show_files & _f_brute_sol)); then
			error_message+="--Brute file    : ${final_brute_sol_file}\n"
			((height+=1))
		fi
		if ((show_files & _f_problem)); then
			error_message+="--Problem file  : RNG_${final_problem_file}.py\n"
			((height+=1))
		fi
	fi
	if ((show_fields != 0)); then
		error_message+="\nSuggested fields:\n"
		((height+=1))
		if ((show_fields & _f_my_sol)); then
			error_message+="--Solution field: ${my_sol_field}\n"
			((height+=1))
		fi
		if ((show_fields & _f_brute_sol)); then
			error_message+="--Brute field   : ${brute_sol_field}\n"
			((height+=1))
		fi
		if ((show_fields & _f_problem)); then
			error_message+="--Problem field : RNG_${problem_field}.py\n"
			((height+=1))
		fi
	fi

	if ((show_files != 0 || show_fields != 0)); then
		error_message+="$(pwd)\n"
		((height+=1))
	fi

	dialog --title "Form Errors" --msgbox "${error_message}" "${height}" "${width}"
}

form() {
	height=15
	width=42
	form_height=6

	local valid_input=1
	while true; do
		if [[ ${valid_input} == 1 ]]; then
			exec 3>&1
			# clean_pwd="${PWD/#${HOME}/~}"
			clean_pwd=$(printf '%s\n' "$PWD" | sed "s@^$HOME@~@")
			result=$(
				dialog \
					--title "${program_name}" \
					--form "${clean_pwd}\nPlease enter the required information" \
					"${height}" "${width}" "${form_height}" \
					"my sol:" 1 1 "" 1 12 20 0 \
					"brute sol:" 2 1 "" 2 12 20 0 \
					"Problem:" 3 1 "" 3 12 20 0 \
					2>&1 1>&3
			)
			return_code=$?
			exec 3>&-

			echo "form return_code: ${return_code}"
		fi

		local breaker=0
		case ${return_code} in
		"${DIALOG_CANCEL}")
			exit
			;;
		"${DIALOG_HELP}")
			exit
			;;
		"${DIALOG_OK}")
			# Extract user inputs
			my_sol=$(echo "${result}" | sed -n '1p')
			brute_sol=$(echo "${result}" | sed -n '2p')
			problem=$(echo "${result}" | sed -n '3p')

			my_sol_field=${my_sol}
			brute_sol_field=${brute_sol}
			problem_field=${problem}

			validate_form_input
			if [[ $? == 1 ]]; then
				decho "the input is valid"
				next_interface=${RNG_template_interface}
				break
			else
				decho "the input is invalid"
				show_form_errors
			fi
			;;

		*)
			echo "ERROR: The Return code was ${return_code}"
			exit
			;;
		esac

		if [[ ${breaker} == 1 ]]; then
			break
		fi

	done
}

retrieve_values() {
	# Attempt to extract values from the file
	my_sol=$(grep '^my_sol=' "${problem_file}" | sed 's/^my_sol="//; s/"$//')
	brute_sol=$(grep '^brute_sol=' "${problem_file}" | sed 's/^brute_sol="//; s/"$//')

	decho "--->my_sol : ${my_sol}"
	decho "--->brute_sol : ${brute_sol}"
	sleep 1

	# Check if the values were successfully retrieved
	if [ -z "${my_sol}" ]; then
		echo "Error: 'my_sol' not found or empty in ${problem_file}"
		return 1
	fi

	if [ -z "${brute_sol}" ]; then
		echo "Error: 'brute_sol' not found or empty in ${problem_file}"
		return 1
	fi

	return 0
}

resolve_exec_command() {
	decho "inside resolve_exec_command"
	decho "${1}"
	decho "${2}"
	solution="$1" # The file name (my_sol or brute_sol)
	exec_var="$2" # The variable name to set (my_exec or brute_exec)

	basename="${solution%.*}"
	decho "------------------------"
	decho "basename= ${basename}"
	ext="${solution##*.}"
	decho "extension: ${ext}"

	case "${ext}" in
	py)
		decho "exec_var: ${exec_var}"
		eval "${exec_var}=\"python3 ${solution}\""
		decho "exec_var: ${exec_var}"
		;;
	cpp)
		decho "exec_var: ${exec_var}"
		if [[ -f "./${basename}.out" ]]; then
			decho "binary \"${basename}.out\" was found."
			eval "${exec_var}=\"./${basename}.out\""
		elif [[ -f "./${basename}" ]]; then
			decho "binary \"${basename}\" was found."
			eval "${exec_var}=\"./${basename}\""
		else
			decho "binary of \"${basename}.cpp\" was not found."
			g++ -std=c++20 "${solution}" -o "${basename}.out"
			decho "${basename}.cpp was compiled as \"${basename}.out\"."
			eval "${exec_var}=\"./${basename}.out\""
		fi
		decho "exec_var: ${exec_var}"
		;;
	java) javac "${solution}" && eval "${exec_var}=\"java ${basename}.java\"" ;;
	go) eval "${exec_var}=\"go run ${solution}\"" ;;
	kt) kotlinc "${solution}" -include-runtime -d "${basename}.jar" && eval "${exec_var}=\"java -jar ${basename}.jar\"" ;;
	*) echo "Unsupported file type for ${solution}: ${solution##*.}" && exit 1 ;;
	esac
}

checker() {
	clear
	decho "INSIDE CHECKER"
	sleep 1

	file="$1"
	problem_file=${file}

	my_sol=""
	brute_sol=""
	my_exec=""
	brute_exec=""

	retrieve_values
	decho "after retrieve_values"
	decho "--->my_sol : ${my_sol}"
	decho "--->brute_sol : ${brute_sol}"

	RNG_exec="python3 ${file}"

	if [[ ! -f ${file} ]]; then # Check if the file exists
		echo "File ${file} does not exist."
		exit 1
	fi

	resolve_exec_command "${my_sol}" "my_exec"
	decho "after first"
	decho "my_exec: ${my_exec}"
	resolve_exec_command "${brute_sol}" "brute_exec"
	decho "after second"
	decho "brute_exec: ${brute_exec}"
	sleep 2

	clear
	decho "my_exec: ${my_exec}"
	decho "brute_exec: ${brute_exec}"
	sleep 2

	set -e

	for ((i = 1; ; ++i)); do
		# ${RNG_exec} "${i}" >.input_file.log
		python3 "${file}" "${i}" >.input_file.log
		${my_exec} <.input_file.log >.answer_my.log
		${brute_exec} <.input_file.log >.answer_correct.log
		diff -Z .answer_my.log .answer_correct.log >/dev/null || break
		echo "Passed test: ${i}"
	done

	echo "WA on the following test:"
	cat .input_file.log
	echo "Your answer is:"
	cat .answer_my.log
	echo "Correct answer is:"
	cat .answer_correct.log
}

fill_common() {
	cat <<'EOF' >"${problem_file}"
import random
import string


def my_print(*args,separator=", ", end="\n"):
    parts = []
    for arg in args:
        if isinstance(arg, (list,tuple)):
            parts.extend(map(str, arg))
        else:
            parts.append(str(arg))

    print(separator.join(parts), end=end)

def cprint(*args, end="\n"): my_print(*args,separator=",",end=end)
def sprint(*args, end="\n"): my_print(*args,separator=" ",end=end)
def csprint(*args, end="\n"): my_print(*args,separator=", ",end=end)
def scprint(*args, end="\n"): my_print(*args,separator=" ,",end=end)

EOF
}

fill_Basic() {
	cat <<'EOF' >>"${problem_file}"
#basic
x = random.randint(1, 10)
EOF
}

fill_n_list() {
	cat <<'EOF' >>"${problem_file}"
#n_list
n = random.randint(1, 10)  # Number of inputs
sprint(n)

for i in range(n):
    sprint(random.randint(1, 10), " " ,end="")
print()

EOF
}

fill_n_Matrix() {
	cat <<'EOF' >>"${problem_file}"
#n_Matrix
n = random.randint(1, 10)  # Number of inputs
sprint(n)
for i in range(n):
    for i in range(n):
        sprint(random.randint(1, 10), "" ,end="")
    print()
print()

EOF
}

fill_nxm_Matrix() {
	cat <<'EOF' >>"${problem_file}"
#nxm_Matrix
n = random.randint(1, 5)  # Number of inputs
m = random.randint(5, 10)  # Number of inputs
sprint(n,m)
for i in range(n):
    for i in range(m):
        sprint(random.randint(1, 10), "" ,end="")
    print()
print()

EOF
}

fill_test_casing() {
	cat <<'EOF' >>"${problem_file}"
#test_casing
t = random.randint(1, 3)  # Number of inputs
n = random.randint(1, 10)  # Number of inputs
sprint(n)

EOF
}

fill_Graph_adj() {
	cat <<'EOF' >>"${problem_file}"
#Graph_adj
#idk, jelp

EOF
}
fill_Graph_matrix() {
	cat <<'EOF' >>"${problem_file}"
#Graph_matrix
#idk, jelp

EOF
}

fill_with_var_data() {
	cat <<EOF >>"${problem_file}"
# -------------------------------------------------------------------------
# DO NOT TOUCH THESE LINES
# -------------------------------------------------------------------------

my_sol="${my_sol}"
	brute_sol="${brute_sol}"

EOF
}

create_RNG_file_according_to_templates() {
	problem_file="RNG_${problem}.py"
	fill_common

	# Read tempfile content as a single line
	input=$(<"${tempfile}")

	IFS='"' read -ra parts <<<"${input}"

	# Process each part
	for part in "${parts[@]}"; do
		# Trim leading and trailing whitespace
		part=$(echo "${part}" | xargs)

		# Skip empty parts
		[ -z "${part}" ] && continue

		# Debugging output
		echo "Processing part: ${part}"

		# Match and call appropriate functions
		case "${part}" in
		Basic)
			fill_Basic
			;;
		"n list")
			fill_n_list
			;;
		"n Matrix")
			fill_n_Matrix
			;;
		"nxm Matrix")
			fill_nxm_Matrix
			;;
		"test casing")
			fill_test_casing
			;;
		"Graph adj")
			fill_Graph_adj
			;;
		"Graph matrix")
			fill_Graph_matrix
			;;
		*)
			echo "Unknown RNG template: '${part}'"
			;;
		esac
	done

	fill_with_var_data
}

editor() {
	DIALOG_ERROR=254
	export DIALOG_ERROR

	# setup edit
	clear
	sleep 1
	echo "CONTENT OF ${problem_file}:"
	cat "${problem_file}"
	sleep 1

	cat "${problem_file}" >"${tempfile}"

	${DIALOG} --title "EDIT BOX" \
		--fixed-font --editbox "${tempfile}" 0 0 2>"${problem_file}"
	local return_code=$?

	clear

	if [[ ${return_code} == 0 ]]; then
		echo "Editing completed. Changes saved to ${problem_file}."
	elif [[ ${return_code} == 1 ]]; then
		echo "Editing canceled."
	else
		echo "An error occurred."
	fi

	sleep 1
	exit
}

RNG_template() {
	tempfile=$( (tempfile) 2>/dev/null) || tempfile=/tmp/test$$
	trap "rm -f ${tempfile}" 0 $SIG_NONE $SIG_HUP $SIG_INT $SIG_QUIT $SIG_TERM

	${DIALOG} \
		--backtitle "No Such Organization" \
		--title "RNG template settings" \
		--checklist "Pick the ones you need\n\
Press SPACE to toggle an option on/off. \n\n" \
		20 61 5 \
		"Basic" "" on "n list" "" off "n Matrix" "" off "nxm Matrix" "" off \
		"test casing" "" off "Graph adj" "" off "Graph matrix" "" off 2>"${tempfile}"
	local return_code=$?

	# report-tempfile
	case "${return_code:-0}" in
	$DIALOG_OK)
		echo "DIALOG_OK"
		echo "Result: $(cat "$tempfile")"
		echo " " >>stress.log
		# cat "$tempfile" >> stress.log
		;;
	$DIALOG_CANCEL)
		echo "DIALOG_CANCEL"
		echo "Cancel pressed."
		;;
	$DIALOG_HELP)
		echo "DIALOG_HELP"
		echo "Help pressed: $(cat "$tempfile")"
		;;
	$DIALOG_ESC)
		echo "DIALOG_ESC"
		if test -s "$tempfile"; then
			cat "$tempfile"
		else
			echo "ESC pressed."
		fi
		;;
	*)
		echo "unexpected return code: ${return_code}"
		exit
		;;
	esac

	# echo "return code in RNG is: ${return_code}"
	create_RNG_file_according_to_templates
	next_interface="${editor_interface}"
}

create_RNG_interface_state_machine() {
	breaker=1
	next_interface=${form_interface}

	while ((breaker == 1)); do

		case ${next_interface} in
		"${form_interface}")
			form
			echo "from form, next interface is: ${next_interface}"
			;;
		"${RNG_template_interface}")
			RNG_template
			echo "from rng, next interface is: ${next_interface}"
			;;
		"${editor_interface}")
			editor
			echo "from editor, next interface is: ${next_interface}"
			;;
		"${end_program}")
			breaker=0
			exit
			;;
		*)
			clear
			echo "unknown interface"
			;;
		esac
	done
}

main() {
	if [[ $# == 1 ]]; then
		checker "$@"
	elif [[ $# == 0 ]]; then
		create_RNG_interface_state_machine
	else
		echo "Invalid: Script expects no more than 1 parameter."
	fi
}

main "$@"
