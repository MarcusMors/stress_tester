#!/bin/bash


# alo
# manuel, juliana
# einmal
# suzammen
# aabend

# gute nacht
# auf wiedersehen (formal)
# tschüs
# bis dann = hasta luego
# bis spater = hasta más tarde
# bis morgen = hasta mañana


# ==============================================================================================
# GLOBAL VARIABLES
# ==============================================================================================

program_name="CP stress tester"
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

form_error_type_not_inferenciable=1
form_error_type_empty_fields=2
form_error_type_inexistant_file=3
form_error_type_problem_already_exists=4
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

validate_form_input() {
	# 0: invalid input
	# 1: valid input

	{
		echo "    "
		echo "my_sol: ${my_sol}"
		echo "brute_sol: ${brute_sol}"
		echo "problem: ${problem}"
	} >>log.txt

	problem_file="RNG_${problem}.py"
	problem_exists=0
	if [[ -n "${problem}" ]]; then
		check_file_exists "${problem_file}"
		problem_exists=$?
	fi

	if ((problem_exists)); then
		# dialog --msgbox "Error: Problem already exists (${problem_file}) . Please try again." 7 50
		form_error_type=${form_error_type_problem_already_exists}
		return 0
	fi

	check_file_exists "${my_sol}"
	my_sol_exists=$?
	check_file_exists "${brute_sol}"
	brute_sol_exists=$?

	echo "my_sol_exists: ${my_sol_exists}" >>log.txt
	echo "brute_sol_exists: ${brute_sol_exists}" >>log.txt
	echo "problem_exists: ${problem_exists}" >>log.txt

	# Infer brute_sol if needed
	local base_name="${my_sol%.*}"

	# if (( !my_sol_exists && !brute_sol_exists)); then
	#     form_error_type=${form_error_type_inexistant_file}
	# fi

	if ((my_sol_exists && !brute_sol_exists)) && [[ -z ${brute_sol} ]]; then
		local extension="${my_sol##*.}"
		local inferred_brute_sol="${base_name}_brute.${extension}"
		echo -e "extension: $extension\nbase_name: $base_name\ninferred_brute_sol: $inferred_brute_sol" >>log.txt

		check_file_exists "${inferred_brute_sol}"
		brute_sol_exists=$?
		brute_sol="${inferred_brute_sol}"
	fi

	# Infer problem if needed
	echo "my_sol_exists: ${my_sol_exists}" >> log.txt
	echo "problem_exists: ${problem_exists}" >> log.txt
	echo "problem: ${problem}" >> log.txt

	if ((my_sol_exists && !problem_exists)) && [[ -z $problem ]]; then
		inferred_problem=${base_name}
		local inferred_problem_file="RNG_${base_name}_brute.py"
		echo -e "extension: $extension\nbase_name: $base_name\ninferred_problem_file: $inferred_problem_file" >>log.txt

		check_file_exists "${inferred_problem_file}"
		problem_exists=$?
		problem_file="${inferred_problem_file}"
		problem=${inferred_problem}
	fi

	echo -e "FINAL my_sol_exists: ${my_sol_exists}\nFINAL brute_sol_exists: ${brute_sol_exists}\nFINAL problem_exists: ${problem_exists}" >>log.txt

	if ((my_sol_exists && brute_sol_exists && !problem_exists)); then
		echo "my_sol: ${my_sol}" >>log.txt
		echo "brute_sol: ${brute_sol}" >>log.txt
		echo "problem: ${problem}" >>log.txt
		return 1
	else
		form_error_type=${form_error_type_empty_fields}
		# form_error_type_not_inferenciable
		return 0
	fi

	return 0
}

i=1
manage_form_error_type() {
	clear
	echo "managing error types: ${i}"
	sleep 2
	((i++))

	# "${form_error_type_not_inferenciable}")
	#     dialog --msgbox "Error: Missing required files. Please try again." 7 50
	#     ;;
	# "${form_error_type_inexistant_file}")
	#     dialog --msgbox "Error: ." 7 50
	#     ;;
	case ${form_error_type} in
	"${form_error_type_empty_fields}")
		dialog --msgbox "Error: Missing required files. Please try again." 7 50
		;;
	"${form_error_type_problem_already_exists}")
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
	width=40
	form_height=6

	local valid_input=1
	while true; do
		if [[ ${valid_input} == 1 ]]; then
			exec 3>&1
			result=$(dialog \
				--form "Please enter the required information" \
				"${height}" "${width}" "${form_height}" \
				"my sol:" 1 1 "" 1 12 15 0 \
				"brute sol:" 2 1 "" 2 12 15 0 \
				"Problem:" 3 1 "" 3 12 15 0 \
				2>&1 1>&3)
			return_code=$?
			exec 3>&-
			clear
			echo "form return_code: ${return_code}"
			sleep 1
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
				clear
				echo "the input is valid"
				sleep 1
				echo "the program continues"

				breaker=1
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
	echo "inside retrieve values"
	sleep 1

	# Attempt to extract values from the file
	my_sol=$(grep '^my_sol=' "${problem_file}" | sed 's/^my_sol="//; s/"$//')
	brute_sol=$(grep '^brute_sol=' "${problem_file}" | sed 's/^brute_sol="//; s/"$//')

	echo "--->my_sol : ${my_sol}"
	echo "--->brute_sol : ${brute_sol}"
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
		echo "inside resolve_exec_command"
		echo "${1}"
		echo "${2}"
    solution="$1"  # The file name (my_sol or brute_sol)
    exec_var="$2"  # The variable name to set (my_exec or brute_exec)

		basename="${solution%.*}"
		echo "basename= ${basename}"
		ext="${solution##*.}"

    case "${ext}" in
        py)
				echo "exec_var: ${exec_var}"
				eval "${exec_var}=\"python3 ${solution}\""
				echo "exec_var: ${exec_var}"
				;;
        cpp)
						echo "cppppppppppppppppppppppppppp"
						echo "exec_var: ${exec_var}"
            if [[ -f "./${basename}.out" ]]; then
								echo "AAAAAAAAAAAAAAAAAAAAAA"
                eval "${exec_var}=\"./${basename}.out\""
            elif [[ -f "./${basename}" ]]; then
								echo "BBBBBBBBBBBBBBBBBBBBBB"
                eval "${exec_var}=\"./${basename}\""
            else
                g++-11 -std=c++20 "${solution}" -o "${basename}.out"
								eval "${exec_var}=\"./${basename}.out\""
            fi
						echo "exec_var: ${exec_var}"
            ;;
        java) javac "${solution}" && eval "${exec_var}=\"java ${basename}.java\"" ;;
        go) eval "${exec_var}=\"go run ${solution}\"" ;;
        kt) kotlinc "${solution}" -include-runtime -d "${basename}.jar" && eval "${exec_var}=\"java -jar ${basename}.jar\"" ;;
        *) echo "Unsupported file type for ${solution}: ${solution##*.}" && exit 1 ;;
    esac
}


checker() {
	clear
	echo "INSIDE CHECKER"
	sleep 1

	file="$1"
	problem_file=${file}

	my_sol=""
	brute_sol=""
	my_exec=""
	brute_exec=""

	echo "gah"
	sleep 1

	retrieve_values
	echo "after retrieve_values"
	echo "--->my_sol : ${my_sol}"
	echo "--->brute_sol : ${brute_sol}"

	RNG_exec="python3 ${file}"

	if [[ ! -f ${file} ]]; then # Check if the file exists
		echo "File ${file} does not exist."
		exit 1
	fi

	echo "gah"
	sleep 2
	resolve_exec_command "${my_sol}" "my_exec"
	echo "after first"
	echo "my_exec: ${my_exec}"
	resolve_exec_command "${brute_sol}" "brute_exec"
	echo "after second"
	echo "brute_exec: ${brute_exec}"

	echo "gah2"
	sleep 2

	clear
	echo "my_exec: ${my_exec}"
	echo "brute_exec: ${brute_exec}"
	sleep 2


	set -e

	for ((i = 1; ; ++i)); do
		${RNG_exec} "${i}" >input_file
		${my_exec} <input_file >answer_my
		${brute_exec} <input_file >answer_correct
		diff -Z answer_my answer_correct >/dev/null || break
		echo "Passed test: ${i}"
	done

	echo "WA on the following test:"
	cat input_file
	echo "Your answer is:"
	cat answer_my
	echo "Correct answer is:"
	cat answer_correct
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
		echo " " >>log.txt
		# cat "$tempfile" >> log.txt
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
	# check if json file exists
	breaker=0
	next_interface=${form_interface}
	while true; do

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
			exit
			;;
		*)
			clear
			echo "unknown interface"
			;;
		esac
	done

	clear
	exit
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
