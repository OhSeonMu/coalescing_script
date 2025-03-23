#!/bin/bash
cd ../../
source ./config.sh

# Function to list all files in a directory and save to an output file
list_files_in_directory_1() {
    local directory_path="$1"
    local output_file="$2"

    if [ ! -d "$directory_path" ]; then
        echo "Error: Directory $directory_path does not exist."
        exit 1
    fi

    > "$output_file" # Clear the output file

    find "$directory_path" -type f | sed "s|^$directory_path/||" >> "$output_file"

    echo "File names have been written to $output_file"
}

list_files_in_directory_2() {
    local directory_path="$1"
    local output_file="$2"

    if [ ! -d "$directory_path" ]; then
        echo "Error: Directory $directory_path does not exist."
        exit 1
    fi

    > "$output_file" # Clear the output file

    find "$directory_path" -type f | sed "s|^$directory_path/||" | sed 's/\.[^.]*$//' >> "$output_file"

    echo "File names have been written to $output_file"
}

# Example usage
directory_to_scan=$TRACE_PATH  # Replace with the target directory
output_file_name="file_list_with_zip.txt"
list_files_in_directory_1 "$directory_to_scan" "$output_file_name"

directory_to_scan=$TRACE_PATH  # Replace with the target directory
output_file_name="file_list_with_out_zip.txt"
list_files_in_directory_2 "$directory_to_scan" "$output_file_name"

