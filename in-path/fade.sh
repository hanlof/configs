#!/bin/bash

# Function to fetch RGB color from X11 rgb.txt by color name (pure Bash, returns via nameref)
get_rgb_color() {
    local color_name="$1"
    local __resultvar="$2"
    local rgb_file="/usr/share/X11/rgb.txt"
    local found=()
    local lc_color_name="${color_name,,}"

    # Treat empty string as error
    if [[ -z "$lc_color_name" ]]; then
        if [[ -n "$__resultvar" ]]; then
            eval "$__resultvar=()"
        else
            echo "Color not found"
        fi
        return 1
    fi

    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*(!|#|$) ]] && continue

        # Split the line into fields
        local fields=()
        read -a fields <<< "$line"
        # Must have at least 4 fields (r g b name)
        (( ${#fields[@]} < 4 )) && continue

        local r="${fields[0]}"
        local g="${fields[1]}"
        local b="${fields[2]}"
        # Reconstruct the color name (may contain spaces)
        local name="${fields[@]:3}"
        local lc_name="${name,,}"

        # Exact match
        if [[ "$lc_name" == "$lc_color_name" ]]; then
            found=("$r" "$g" "$b")
            break
        fi

        # First partial match
        if [[ ${#found[@]} -eq 0 && "$lc_name" == *"$lc_color_name"* ]]; then
            found=("$r" "$g" "$b")
            # Don't break, keep looking for exact match
        fi
    done < "$rgb_file"

    if [[ ${#found[@]} -gt 0 ]]; then
        if [[ -n "$__resultvar" ]]; then
            eval "$__resultvar=(${found[@]})"
        else
            echo "${found[@]}"
        fi
        return 0
    else
        if [[ -n "$__resultvar" ]]; then
            eval "$__resultvar=()"
        else
            echo "Color not found"
        fi
        return 1
    fi
}

fade() {
    local total_ms="$1"
    local start_r="$2"
    local start_g="$3"
    local start_b="$4"
    local end_r="$5"
    local end_g="$6"
    local end_b="$7"
    local sleep_ms=30

    # Calculate the number of steps as a float, then round
    local steps=$(awk "BEGIN { s = $total_ms / $sleep_ms; print int(s < 2 ? 2 : s) }")
    # Pre-calculate the sleep delay in seconds (as a string)
    local actual_sleep_ms=$(awk "BEGIN { printf \"%.6f\", $total_ms / $steps }")
    local sleep_delay=$(awk "BEGIN { printf \"%.6f\", $actual_sleep_ms/1000 }")

    for ((i=0; i<steps; i++)); do
        local value=$(( i * 1000 / (steps - 1) ))
        # Calculate proportional r, g, b values (from start to end)
        local curr_r=$(( start_r + (end_r - start_r) * value / 1000 ))
        local curr_g=$(( start_g + (end_g - start_g) * value / 1000 ))
        local curr_b=$(( start_b + (end_b - start_b) * value / 1000 ))
        # Output xterm control sequence to set background color
        printf "\033]11;rgb:%02x/%02x/%02x\007" "$curr_r" "$curr_g" "$curr_b"
        sleep "$sleep_delay"
    done
}

# Trap Ctrl+C (SIGINT) to reset background color before exiting
trap 'printf "\033]11;XtDefaultBackground\007"; echo; exit 130' INT

# Function to execute the main logic
main() {
    echo "Starting the main script..."

    local color_name="red"
    local milliseconds=1000
    local rgb=()
    local start_rgb=(0 0 0)
    local repeatmode="once"
    local mode="ramp"  # default mode

    local color_args=()  # To store color arguments

    # Argument parsing
    for arg in "$@"; do
        if [[ "$arg" == "repeat" || "$arg" == "once" ]]; then
            repeatmode="$arg"
        elif [[ "$arg" == "ramp" || "$arg" == "bounce" ]]; then
            mode="$arg"
        elif [[ "$arg" =~ ^([0-9]*\.[0-9]+|[0-9]+)$ ]]; then
            # If arg contains a dot, treat as seconds (float), else as integer seconds
            if [[ "$arg" == *.* ]]; then
                milliseconds=$(awk "BEGIN { printf \"%d\", $arg * 1000 }")
            elif (( arg < 100 )); then
                milliseconds=$((arg * 1000))
            else
                milliseconds=$arg
            fi
        else
            color_args+=("$arg")
        fi
    done

    # Handle color arguments (names)
    if [[ ${#color_args[@]} -eq 2 ]]; then
        # Two color names: first is start, second is end
        get_rgb_color "${color_args[0]}" start_rgb
        if [[ ${#start_rgb[@]} -eq 0 ]]; then
            echo "Error: Start color '${color_args[0]}' not found."
            exit 1
        fi
        get_rgb_color "${color_args[1]}" rgb
        if [[ ${#rgb[@]} -eq 0 ]]; then
            echo "Error: End color '${color_args[1]}' not found."
            exit 1
        fi
        echo "Start color: ${color_args[0]} -> ${start_rgb[*]}"
        echo "End color:   ${color_args[1]} -> ${rgb[*]}"
    elif [[ ${#color_args[@]} -eq 1 ]]; then
        # One color name: start is default, end is given
        get_rgb_color "${color_args[0]}" rgb
        if [[ ${#rgb[@]} -eq 0 ]]; then
            echo "Error: End color '${color_args[0]}' not found."
            exit 1
        fi
        echo "End color: ${color_args[0]} -> ${rgb[*]}"
    else
        # No color argument: use default end color
        get_rgb_color "$color_name" rgb
        echo "End color: $color_name -> ${rgb[*]}"
    fi

    if [[ -n "$milliseconds" ]]; then
        echo "Milliseconds: $milliseconds"
    fi

    echo "Mode: $mode"

    if [[ "$repeatmode" == "repeat" ]]; then
        echo "Running in repeat mode (Ctrl+C to stop)..."
        while true; do
            if [[ "$mode" == "bounce" ]]; then
                fade "$milliseconds" "${start_rgb[0]}" "${start_rgb[1]}" "${start_rgb[2]}" "${rgb[0]}" "${rgb[1]}" "${rgb[2]}"
                fade "$milliseconds" "${rgb[0]}" "${rgb[1]}" "${rgb[2]}" "${start_rgb[0]}" "${start_rgb[1]}" "${start_rgb[2]}"
            else
                fade "$milliseconds" "${start_rgb[0]}" "${start_rgb[1]}" "${start_rgb[2]}" "${rgb[0]}" "${rgb[1]}" "${rgb[2]}"
            fi
        done
    else
        if [[ "$mode" == "bounce" ]]; then
            fade "$milliseconds" "${start_rgb[0]}" "${start_rgb[1]}" "${start_rgb[2]}" "${rgb[0]}" "${rgb[1]}" "${rgb[2]}"
            fade "$milliseconds" "${rgb[0]}" "${rgb[1]}" "${rgb[2]}" "${start_rgb[0]}" "${start_rgb[1]}" "${start_rgb[2]}"
        else
            fade "$milliseconds" "${start_rgb[0]}" "${start_rgb[1]}" "${start_rgb[2]}" "${rgb[0]}" "${rgb[1]}" "${rgb[2]}"
        fi
    fi

    # Reset background palette to XtDefaultBackground after fading
    printf "\033]11;XtDefaultBackground\007"

    echo "Main script execution completed."
}

# Only execute main if the script is run directly, not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
# End of script