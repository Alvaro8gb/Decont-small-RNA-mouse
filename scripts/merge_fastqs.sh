# This script should merge all files from a given sample (the sample id is
# provided in the third argument ($3)) into a single file, which should be
# stored in the output directory specified by the second argument ($2).
#
# The directory containing the samples is indicated by the first argument ($1).


input_dir="$1"
output_dir="$2"
sample_id="$3"


merged_file="$output_dir"/"${sample_id}_merged.fastq.gz"

if [ -f "$merged_file" ]; 
then
    echo "Skipping $sid: $merged_file already exists."
    
else
    cat "$input_dir"/"${sample_id}"* > $merged_file
    echo "File created" $merged_file
fi
