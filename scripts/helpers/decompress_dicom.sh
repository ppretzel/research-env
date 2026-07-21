#!/usr/bin/env bash
#
# decompress_dicom.sh
#
# Recursively decompresses all DICOM files under an input directory
# (and all its subfolders) using gdcmconv --raw, writing the results
# to a separate output directory with the same folder structure.
# Original files are left untouched.
#
# Useful if mrtrix complains about the TransferSyntax.
#
# Usage:
#   ./decompress_dicom.sh /path/to/input_dir /path/to/output_dir
#
set -euo pipefail

if [ $# -ne 2 ]; then
    echo "Usage: $0 <input_directory> <output_directory>" >&2
    exit 1
fi

in_dir="$1"
out_dir="$2"


mkdir -p "$out_dir"

# Count total files up front so we can report progress against a total.
total=$(find "$in_dir" -type f | wc -l)
echo "Found $total file(s) under '$in_dir'."

count=0
failed=0

while IFS= read -r -d '' img; do
    # Path of this file relative to in_dir, so we can mirror the
    # subfolder structure under out_dir.
    rel_path="${img#"$in_dir"/}"
    target="$out_dir/$rel_path"
    target_dir=$(dirname "$target")

    mkdir -p "$target_dir"

    if gdcmconv --raw "$img" "$target" 2>/dev/null; then
        count=$((count + 1))
    else
        echo "Failed to convert: $img" >&2
        rm -f "$target"
        failed=$((failed + 1))
    fi

    done_so_far=$((count + failed))
    remaining=$((total - done_so_far))
    echo -ne "Progress: $done_so_far/$total converted (ok: $count, failed: $failed, remaining: $remaining)\r"

done < <(find "$in_dir" -type f -print0)

echo ""
echo "Done. Converted: $count, Failed: $failed, Total: $total"
