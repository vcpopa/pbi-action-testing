#!/bin/bash

# Unpack the pbit file
unpack_pbit() {
    local pbit_file="$1"
    local tmp_dir="$2"
    if [ -e "$pbit_file" ]; then
        7z x "$pbit_file" -o"$tmp_dir"
    else
        echo "Error: $pbit_file is not an existing pbit file."
        exit 3
    fi
}

# Rename and convert files to JSON format
add_extensions() {
    local tmp_dir="$1"
    for file in Connections DiagramLayout Metadata Settings Report/Layout DataModelSchema; do
        local src_path="$tmp_dir/$file"
        if [ -e "$src_path" ]; then
            iconv -f UTF-16LE -t UTF-8 "$src_path" > "$src_path.json"
            rm -f "$src_path"
        fi
    done
}

# Unzip the DataMashup file
unpack_data_mashup() {
    local tmp_dir="$1"
    local data_mashup_path="$tmp_dir/DataMashup"
    if [ -e "$data_mashup_path" ]; then
        7z x "$data_mashup_path" -o"$tmp_dir"
    else
        echo "Error: Couldn't find a DataMashup file in $tmp_dir"
        exit 3
    fi
}

# Remove binary files from the pbit file
remove_binaries() {
    local tmp_dir="$1"
    rm -f "$tmp_dir/SecurityBindings" "$tmp_dir/DataMashup"
}

# Reformat JSON files for readability
reformat_jsons() {
    local tmp_dir="$1"
    find "$tmp_dir" -name "*.json" -type f -exec jq . '{}' > '{}.tmp' \; -exec mv '{}.tmp' '{}' \;
}

# Main script
echo "=== Start of PBIT processing ===="

# Check if required tools are installed
if ! command -v 7z &> /dev/null || ! command -v jq &> /dev/null; then
    echo "Error: Required tools 7z and jq are not installed."
    exit 1
fi

# Unpack all the zipfiles (if the pbit has been staged)
pbitFiles=$(gh pr diff $PR_NUMBER --name-only)
for pbit_file in $pbitFiles; do
    if [ "${pbit_file##*.}" == "pbit" ]; then
        tmp_dir=$(mktemp -d)
        unpack_pbit "$pbit_file" "$tmp_dir"
        add_extensions "$tmp_dir"
        unpack_data_mashup "$tmp_dir"
        remove_binaries "$tmp_dir"
        reformat_jsons "$tmp_dir"
        # Clean up the temporary directory
        rm -rf "$tmp_dir"
    fi
done

echo "=== End of PBIT processing ==="
echo