#!/bin/bash


# This script should download the file specified in the first argument ($1),
# place it in the directory specified in the second argument ($2),
# and *optionally*:
# - uncompress the downloaded file with gunzip if the third
#   argument ($3) contains the word "yes"
# - filter the sequences based on a word contained in their header lines:
#   sequences containing the specified word in their header should be **excluded**
#
# Example of the desired filtering:
#
#   > this is my sequence
#   CACTATGGGAGGACATTATAC
#   > this is my second sequence
#   CACTATGGGAGGGAGAGGAGA
#   > this is another sequence
#   CCAGGATTTACAGACTTTAAA
#
#   If $4 == "another" only the **first two sequence** should be output


# Usage: download.sh <url> <output_dir> [uncompress] [exclude_word]
# Example: download.sh "http://example.com/file.fasta.gz" ./data yes another

set -e

url="$1"
outdir="$2"
uncompress="$3"
exclude_word="$4"

mkdir -p "$outdir"
filename=$(basename "$url")
filepath="$outdir/$filename"


# Download the file with wget if it doesn't exist
if [[ -f "$filepath" ]]; then
	echo "File $filepath already exists. Skipping download."
else
	wget -O "$filepath" "$url"
fi

# MD5 check (do not save md5 file)
expected_md5=$(wget -qO- "${url}.md5" | awk '{print $1}')
actual_md5=$(md5sum "$filepath" | awk '{print $1}')

if [[ "$expected_md5" != "$actual_md5" ]]; then
	echo "Warning: MD5 mismatch for $filepath. Expected $expected_md5, got $actual_md5."
else
	echo "MD5 check passed for $filepath."
fi

# Uncompress if requested
if [[ "$uncompress" == "yes" ]]; then
    echo "Uncompressing $filepath"
    gunzip -c "$filepath" > "${filepath%.gz}"
    filepath="${filepath%.gz}"
fi
 
# Filter sequences if exclude_word is provided
if [[ -n "$exclude_word" ]]; then
    tmpfile="${filepath}.tmp"
    awk -v word="$exclude_word" '
        BEGIN { RS=">"; ORS="" }
        NR > 1 {
            header = substr($0, 1, index($0, "\n") - 1)
            seq    = substr($0, index($0, "\n") + 1)
            if (header !~ word)
                print ">" header "\n" seq
        }
    ' "$filepath" > "$tmpfile"
    mv "$tmpfile" "$filepath"
    echo "Filtered file written to $filepath"
else
    echo "File downloaded to $filepath"
fi

