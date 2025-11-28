# This script should index the genome file specified in the first argument ($1),
# creating the index in a directory specified by the second argument ($2).

# The STAR command is provided for you. You should replace the parts surrounded
# by "<>" and uncomment it.

# STAR --runThreadN 4 --runMode genomeGenerate --genomeDir <outdir> \
# --genomeFastaFiles <genomefile> --genomeSAindexNbases 9

genomefile="$1"
outdir="$2"

# Check if index already exists (look for SA file in index directory)
if [[ -f "$outdir/SA" ]]; then
    echo "Index already exists in $outdir. Skipping indexing."
else
    echo "Running STAR index..."
    mkdir -p "$outdir"
    STAR --runThreadN 4 --runMode genomeGenerate --genomeDir "$outdir" \
        --genomeFastaFiles "$genomefile" --genomeSAindexNbases 9
fi

