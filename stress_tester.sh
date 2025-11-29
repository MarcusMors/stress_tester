#!/bin/bash
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

result=""

next_interface=0
valid_input=0

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
	[not_inferenciable]=1
	[inexistant_file]=2
	[problem_already_exists]=3
	[empty_all]=4
	[empty_problem]=5
	[empty_solution]=6
	[empty_brute_solution]=7
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


# ==============================================================================================
# END GLOBAL SCOPE
# ==============================================================================================

debugging=1
dlog(){
	# The purpose of dlog is ...
	file="debug.log"
	if [[ ${debugging} == 1 ]]; then
		echo "$@" >> ${file}
	fi
}

decho(){
	if [[ ${debugging} == 1 ]]; then
		echo "$@"
	fi
}

# ==============================================================================================
# END DEBUG FUNCTIONS
# ==============================================================================================

classify_filename() {
    local fname="$1"
    local flags=0

    # INVALID: empty, ends with dot, or starts with dot + has another dot
    if [[ -z "$fname" || "$fname" =~ \.$ || "$fname" =~ ^\.[^.]*\. ]]; then
        echo 0
        return
    fi

    # Mark as valid
    ((flags |= 4))

    # EXTENSION ONLY: ^\.[^.]+$
    if [[ "$fname" =~ ^\.[^.]+$ ]]; then
        ((flags |= 2))  # has_ext=1, has_base=0
        echo "$flags"
        return
    fi

    # BASENAME ONLY: ^[^.]+$
    if [[ "$fname" =~ ^[^.]+$ ]]; then
        ((flags |= 1))  # has_base=1, has_ext=0
        echo "$flags"
        return
    fi

    # FULL FILENAME: ^[^.]+\.[^.]+$
    if [[ "$fname" =~ ^[^.]+\.[^.]+$ ]]; then
        ((flags |= 3))  # has_base=1, has_ext=1
        echo "$flags"
        return
    fi

    # Anything else is invalid
    echo 0
}

# ---------- Your Requested API (1=true, 0=false) ----------

has_basename() {
    local var_name="$1"
    local true_ret="${2:-1}"
    local value="${!var_name}"
    local category=$(classify_filename "$value")

    if ((category & 1)); then
        return "$true_ret"
    else
        return 0
    fi
}

has_extension() {
    local var_name="$1"
    local true_ret="${2:-1}"
    local value="${!var_name}"
    local category=$(classify_filename "$value")

    if ((category & 2)); then
        return "$true_ret"
    else
        return 0
    fi
}

is_invalid() {
    local var_name="$1"
    local true_ret="${2:-1}"
    local value="${!var_name}"
    local category=$(classify_filename "$value")

    if ((category == 0)); then
        return "$true_ret"
    else
        return 0
    fi
}

copy_assoc_array() {
    declare -n src="$1"
    declare -n dst="$2"

    for key in "${!src[@]}"; do
        dst["$key"]="${src[$key]}"
    done
}

is_empty() {
    local var_name="$1"
    local true_ret="${2:-1}"   # default return value = 1

    # expand the variable by name
    local value="${!var_name}"

    if [[ -z "$value" ]]; then
        return "$true_ret"
    else
        return 0
    fi
}

file_exists() {
    local var_name="$1"
    local true_ret="${2:-1}"

    local value="${!var_name}"

    if [[ -f "$value" ]]; then
        return "$true_ret"
    else
        return 0
    fi
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

calculate_form_flags(){
	local arr_name="$1"
	shift
	my_sol="$1"
	brute_sol="$2"
	problem="$3"

	f_is_empty=1
	f_file_exists=2         
	f_has_basename=4         
	f_has_extension=8         
	f_is_invalid=16      
	f_inferenciable=32      
	
	is_empty my_sol f_is_empty; f_my_sol=$?
	is_empty brute_sol f_is_empty; f_brute_sol=$?
	is_empty problem f_is_empty; f_problem=$?


	file_exists my_sol f_file_exists; f_my_sol=$((f_my_sol | $?))
	file_exists brute_sol f_file_exists; f_brute_sol=$((f_brute_sol | $?))
	problem_file="RNG_${problem}.py"
	file_exists problem_file f_file_exists; f_problem=$((f_problem | $?))

	has_basename my_sol f_has_basename; f_my_sol=$((f_my_sol | $?))
	has_extension my_sol f_has_extension; f_my_sol=$((f_my_sol | $?))
	is_invalid my_sol f_is_invalid; f_my_sol=$((f_my_sol | $?))
	
	has_basename brute_sol f_has_basename; f_brute_sol=$((f_brute_sol | $?))
	has_extension brute_sol f_has_extension; f_brute_sol=$((f_brute_sol | $?))
	is_invalid brute_sol f_is_invalid; f_brute_sol=$((f_brute_sol | $?))

	local basename="${my_sol%.*}"
	local brute_basename="${brute_sol%.*}"

	########### Infer calculations ###########
	# if my_sol is not empty && valid
		# if my_sol has basename and extension: then inferable=f_is_inferenciable.
		# if my_sol has basename and no extension: then my_sol=basename + extension of brute_sol, inferable=f_is_inferenciable
		# if my_sol has no basename and extension: then my_sol=brute_sol without _brute + extension, inferable=f_is_inferenciable
	# else # my_sol is empty
		# mysol=brute_sol without _brute preffix if possible, else: it's not inferable; inferable=f_is_inferenciable
	# fi
	# if my_sol is inferenciable; then updated my_sol_exists and my_sol_empty and invalid=0

	# if brute_sol is not empty && valid
		# if brute_sol has basename and extension: then inferable=f_is_inferenciable.
		# if brute_sol has basename and no extension: then brute_sol=basename + extension of my_sol, inferable=f_is_inferenciable
		# if brute_sol has no basename and extension: then brute_sol=my_sol + extension, inferable=f_is_inferenciable
	# else # brute_sol is empty
		# brute_sol=my_sol with _brute preffix; inferable=f_is_inferenciable
	# fi

	# if brute_sol is inferenciable; then updated brute_sol_exists and brute_sol_empty and invalid=0

	# if problem is empty; then
		# if my_sol is not empty; then problem=basename of my_sol and update problem_file_exists,problem_empty,inferable=f_is_inferenciable
		# elif brute_sol is not empty; then problem=basename of brute_sol without _brute and update problem_file_exists,problem_empty,inferable=f_is_inferenciable
		# fi
	# fi

	eval "$arr_name=()"
	items=(f_my_sol,f_brute_sol,f_problem)
	
	# Fill array with parameters
	for item in "$@"; do
			eval "$arr_name+=(\"$item\")"
	done
}

validate_form_input() {
	# return 0: invalid input
	# return 1: valid input
	f_empty=1
	f_file_exists=2         
	f_inferenciable=4        

	# vars\flags| empty | file exists | inferenciable
	sol_brute_problem_flags=()
	calculate_form_flags sol_brute_problem_flags my_sol brute_sol problem
	# dlog "sol_brute_problem_flags: ${sol_brute_problem_flags[@]}"

	dlog "    "
	dlog "my_sol: ${my_sol}"
	dlog "brute_sol: ${brute_sol}"
	dlog "problem: ${problem}"

	problem_file="RNG_${problem}.py"
	problem_exists=0
	
	
	# Create problem_file

	# is_empty problem f_empty
	if [[ -n "${problem}" ]]; then
		check_file_exists "${problem_file}"
		problem_exists=$?
		if ((problem_exists == 1)); then
			form_errors+=${problem_already_exists}
			return 0
		fi
	fi


	check_file_exists "${my_sol}"
	my_sol_exists=$?
	check_file_exists "${brute_sol}"
	brute_sol_exists=$?

	dlog "my_sol_exists: ${my_sol_exists}"
	dlog "brute_sol_exists: ${brute_sol_exists}"
	dlog "problem_exists: ${problem_exists}"

	local basename="${my_sol%.*}"
	local brute_basename="${my_sol%.*}"

	# if (( !my_sol_exists && !brute_sol_exists)); then
	#     form_error_type=${form_error_type__inexistant_file}
	# fi

	# Infer my_sol if needed


	
	# Infer brute_sol if needed
	if ((my_sol_exists && !brute_sol_exists)) && [[ -z ${brute_sol} ]]; then
		local extension="${my_sol##*.}"
		local inferred_brute_sol="${basename}_brute.${extension}"
		dlog "extension: $extension"
		dlog "basename: $basename"
		dlog "inferred_brute_sol: $inferred_brute_sol"

		check_file_exists "${inferred_brute_sol}"
		brute_sol_exists=$?
		brute_sol="${inferred_brute_sol}"
	fi

	# Infer problem if needed
	echo "my_sol_exists: ${my_sol_exists}" >> stress.log
	echo "problem_exists: ${problem_exists}" >> stress.log
	echo "problem: ${problem}" >> stress.log

	if ((my_sol_exists && !problem_exists)) && [[ -z $problem ]]; then
		inferred_problem=${basename}
		local inferred_problem_file="RNG_${basename}_brute.py"
		dlog "extension: $extension"
		dlog "basename: $basename"
		dlog "inferred_problem_file: $inferred_problem_file"

		check_file_exists "${inferred_problem_file}"
		problem_exists=$?
		problem_file="${inferred_problem_file}"
		problem=${inferred_problem}
	fi

	dlog "FINAL my_sol_exists: ${my_sol_exists}"
	dlog "FINAL brute_sol_exists: ${brute_sol_exists}"
	dlog "FINAL problem_exists: ${problem_exists}"

	if ((my_sol_exists && brute_sol_exists && !problem_exists)); then
		dlog "my_sol: ${my_sol}"
		dlog "brute_sol: ${brute_sol}"
		dlog "problem: ${problem}"
		return 1
	else
		form_error_type=${form_error_type__empty_fields}
		form_errors+=("empty_all")
		# form_error_type__not_inferenciable
		return 0
	fi

	return 0
}

manage_form_error_type() {
	# "${form_error_type__not_inferenciable}")
	#     dialog --msgbox "Error: Missing required files. Please try again." 7 50
	#     ;;
	# "${form_error_type__inexistant_file}")
	#     dialog --msgbox "Error: ." 7 50
	#     ;;

	error_messages=()
	declare -A errors
	copy_assoc_array form_error_types errors
	for e in "${form_errors[@]}"; do
    case ${errors[$e]} in
        ${errors[not_inferenciable]})
            error_messages+=("Not inferenciable error detected.\n")
            ;;
        ${errors[empty_all]})
            error_messages+=("Not inferenciable error detected.\n")
            ;;
        ${errors[inexistant_file]})
            error_messages+=("Not inferenciable error detected.\n")
            ;;
        ${errors[problem_already_exists]})
						# "Error: Problem already exists (${problem_file}) . Please try again." 7 50
            error_messages+=("Not inferenciable error detected.\n")
            ;;
        *)
            error_messages+=("Not inferenciable error detected.\n")
            ;;
    esac
	done

	

	case ${form_error_type} in
	"${form_error_type__empty_fields}")
		dialog --msgbox "Error: Missing required files. Please try again." 7 50
		;;
	"${form_error_type__problem_already_exists}")
		dialog --msgbox "Error: The RNG_${problem}.py already exists." 7 50
		;;
	*)
		echo "unknown error type"
		exit
		;;
	esac
}

form() {
	height=15
	width=42
	form_height=6

	local valid_input=1
	while true; do
		if [[ ${valid_input} == 1 ]]; then
			exec 3>&1
			result=$(
				dialog \
				--title "${program_name}" \
				--form "Please enter the required information" \
				"${height}" "${width}" "${form_height}" \
				"my sol:" 1 1 "" 1 12 20 0 \
				"brute sol:" 2 1 "" 2 12 20 0 \
				"Problem:" 3 1 "" 3 12 20 0 \
				2>&1 1>&3
				)
			return_code=$?
			exec 3>&-

			echo "form return_code: ${return_code}"
			
		else
			manage_form_error_type
			valid_input=1
			continue
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

			validate_form_input
			valid_input=$?

			if [[ ${valid_input} == 1 ]]; then
				decho "the input is valid"
				next_interface=${RNG_template_interface}
				break
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
    solution="$1"  # The file name (my_sol or brute_sol)
    exec_var="$2"  # The variable name to set (my_exec or brute_exec)

		basename="${solution%.*}"
		echo "basename= ${basename}"
		ext="${solution##*.}"

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
                g++-11 -std=c++20 "${solution}" -o "${basename}.out"
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
	
	IFS='"' read -ra parts <<< "${input}"

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

	cat "${problem_file}" > "${tempfile}"

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