#!/usr/bin/bash

# --- FUNCTION: Copy associative array using nameref ---
copy_assoc_array() {
    declare -n src="$1"
    declare -n dst="$2"

    for key in "${!src[@]}"; do
        dst["$key"]="${src[$key]}"
    done
}

# --- ORIGINAL associative array (error types) ---
declare -A form_error_type=(
    [not_inferenciable]=1
    [empty_fields]=2
    [inexistant_file]=3
    [problem_already_exists]=4
)

# --- COPY the associative array ---

# --- Normal array to store triggered errors ---
errors=()
errors+=("empty_fields")
errors+=("problem_already_exists")

declare -A errors_map
copy_assoc_array form_error_type errors_map
# --- Process and report errors using the copied array ---
for e in "${errors[@]}"; do
    case ${errors_map[$e]} in
        ${errors_map[not_inferenciable]})
            echo "Not inferenciable error detected."
            ;;
        ${errors_map[empty_fields]})
            echo "Empty fields error detected."
            ;;
        ${errors_map[inexistant_file]})
            echo "Inexistant file error detected."
            ;;
        ${errors_map[problem_already_exists]})
            echo "Problem already exists error detected."
            ;;
        *)
            echo "Unknown error type."
            ;;
    esac
done
