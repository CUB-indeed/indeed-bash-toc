#!/bin/bash

walk_dir() {
    shopt -s nullglob dotglob

    local directories=()

    for pathname in "$1"/*; do
        if [[ ! "$pathname" =~ /\. ]]; then
            if [[ -d "$pathname" ]]; then
                local subdirectories=()
                directories+=("$pathname")
                subdirectories=($(walk_dir "$pathname"))
                directories+=("${subdirectories[@]}")
            else
                directories+=("$pathname")
            fi
        fi
    done

    echo "${directories[@]}"
}

main() {
    local out_path=$1
    ROOT_PATH="./"

    result=($(walk_dir "$ROOT_PATH"))

    # Create a temporary file
    temp_file=$(mktemp)


    for directory in "${result[@]}"; do
        echo "$directory"
    done

    # Write the directories to the temporary file
    for directory in "${result[@]}"; do
        files=()
        IFS="/" read -ra parts <<< "$directory"
        for element in "${parts[@]}"; do
            if [[ "$element" != "" && "$element" != "." ]]; then
                files+=("$element")
            fi
        done
        tabs_n="${#files[@]}"
        tabs=""
        for ((i=1; i<=tabs_n; i++)); do
            tabs+="  "
        done
        echo "${tabs}- [${files[${#files[@]} - 1]}]($directory)"
        # printf "%s- [$directory](#$directory)\n" "$tabs"
    done > "$temp_file"

    # Find the position of <!--ts--> tag in $out_path
    ts_line=$(grep -n '<!--ts-->' $out_path | cut -d ':' -f 1)

    # Find the position of <!--te--> tag in $out_path
    te_line=$(grep -n '<!--te-->' $out_path | cut -d ':' -f 1)

    # Determine the sed command based on the operating system
    if [[ $(uname) == "Darwin" ]]; then
        sed_cmd=("sed" "-i" "" "-e")
    else
        sed_cmd=("sed" "-i" "-e")
    fi

    # Clear existing data between <!--ts--> and <!--te--> tags
    if ! (( $ts_line + 1 == $te_line )); then
        new_ts_line=$((ts_line + 1))
        new_te_line=$((te_line - 1))
        if [[ -n "$ts_line" && -n "$te_line" ]]; then
            "${sed_cmd[@]}" "$new_ts_line,$new_te_line d" $out_path
        fi
    fi

    # Append the content of the temporary file between <!--ts--> and <!--te--> tags
    if [[ -n "$ts_line" && -n "$te_line" ]]; then
        "${sed_cmd[@]}" "$ts_line r $temp_file" $out_path
        printf '%s\n' "Done creating TOC on $out_path"
    else
        printf '%s\n' "Please insert the tag in to the $out_path file"
    fi

    # Remove the temporary file
    rm "$temp_file"
}

# Create arguments
while getopts o: flag
do
    case "${flag}" in
        o) output_path=${OPTARG};;
    esac
done
main "$output_path"
