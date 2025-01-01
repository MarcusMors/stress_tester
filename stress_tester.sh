#!/bin/bash

reset="\033[0m"
black="\033[30m"
red="\033[31m"
green="\033[32m"
yellow="\033[33m"
blue="\033[34m"
magenta="\033[35m"
cyan="\033[36m"
white="\033[37m"
black_bg="\033[40m"
red_bg="\033[41m"
green_bg="\033[42m"
yellow_bg="\033[43m"
blue_bg="\033[44m"
magenta_bg="\033[45m"
cyan_bg="\033[46m"
white_bg="\033[47m"
default_bg="\033[49m"
bold="\033[1m"
underline="\033[4m"
inverse="\033[7m"
bold_off="\033[21m"
underline_off="\033[24m"
inverse_off="\033[27m"

# This file is the main executable that creates STF's
# STF means stress tester file.

# How to use it:
# "stress_tester" executes the most recently executed STF.
# "stress_tester --name='STF_name'" executes that STF.

# Functions
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

function DialogGen () {
    integer height=15
    integer width=40
    integer form_height=6

    dialog --form "please enter the required information" \
    $height $width $form_height \
    "Name:" 1 1 "" 1 12 15 0 \
    "Age:"  2 1 "" 2 12 15 0 \
    "Mail id:" 4 3 "" 4 15 10 0 \
    # "Mail idd:" 5 1 "" 5 12 15 0 
}

scape_key=$'\e'
backspace_key=$'\x7f'

read_keypress() {
    # read: Reads input from the user or standard input.
    # -r: Prevents the interpretation of backslashes (\) as escape characters.
    # -s: Silences the input, so it doesn't echo what the user types.
    # -n1: Limits input to 1 character.
    # key: The variable where the input is stored.
    IFS= read -rsn1 key

    if [[ $key == $'\e' ]]; then
        echo "ESC"
    else
        echo "$key"
    fi
}

mode__insert="i"
mode__quit="q"
mode__scape="esc"


# Usage examples

interface_insert_mode(){

    echo "aaa"
    while true; do
        echo "aaaa"

        sync
        echo "columns: ${COLUMNS}"
        sync
        height=$(tput lines)
        sync
        echo "height: ${height}"
        sync
        # Read user input for insertion
        echo -n "Input: ${user_input}"
        sync
        key=$(read_keypress)
        sync

        case "$key" in
            "$backspace_key")
                if [[ -n ${user_input} ]]; then
                    user_input=${user_input:0:-1}
                fi
                ;;
            "$scape_key")
                echo
                echo "key: ${key}"
                echo
                return ${mode__scape}
                ;;
            *)
                echo
                echo "key: ${key}"
                echo
                user_input="$user_input$key"
                ;;
        esac
        
        sync
    done
}


interface_state_machine(){
    echo "a"
    mode="${mode__insert}"
    while true; do 
        case "$mode" in
            $mode__insert)
                echo "aa"
                mode=${interface_insert_mode}
                ;;
            $mode__quit)
                exit 1
                ;;
            $mode__scape)
                key=$(read_keypress)
                mode=key
                ;;
            *)
                echo "Unknown mode."
                echo "mode: $mode"
                key=$(read_keypress)
                mode=key
                ;;
        esac
        println ${yellow} "ingrese un modo [i,q]"
    done


    true;
}


main() {
    interface_state_machine
}

main

# detect input h j k l or directional keys


# detect input q or esc to quit


