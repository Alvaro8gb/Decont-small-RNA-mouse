# PARAMETERS

# Reference and index files
CONTA_FILE="res/contaminants.fasta"
CONTA_IDX="res/contaminants_idx"
REF_URL="https://bioinformatics.cnio.es/data/courses/decont/contaminants.fasta.gz"

# Input/output directories
IN_DATA="data"
OUT_DATA="out"

LOG="log"
LOG_CUT="$LOG/cutadapt"
LOG_SUM="$LOG/summary.log"

OUT_MERG="$OUT_DATA/merged"
OUT_CUT="$OUT_DATA/cutadapt"
OUT_STAR="$OUT_DATA/star"
OUT_MULTIQC="$OUT_DATA/multiqc"

# Number of threads
THREADS=4


# CODE

# Download all the files specified in data/filenames

for url in $(cat data/urls) 
do
    echo "Downloading $url in $IN_DATA$"
    bash scripts/download.sh $url $IN_DATA
done

# Download the contaminants fasta file, uncompress it, and
# filter to remove all small nuclear RNAs

if [ -f "$CONTA_FILE" ]; then
    echo "$CONTA_FILE already exists. Skipping download."
else
    bash scripts/download.sh $REF_URL res yes snRNA
fi


# Index the contaminants file
bash scripts/index.sh $CONTA_FILE $CONTA_IDX


# Get unique sample IDs from input FASTQ files
SAMPLES_IDS=$(find "$IN_DATA" -maxdepth 1 -name "*.fastq.gz" | \
    xargs -n1 basename | cut -d"_" -f1 | sort | uniq)


echo "Running pipline on $SAMPLES_IDS"

# Merge the samples into a single file

mkdir -p $OUT_MERG

for sid in $SAMPLES_IDS; 
do 
    echo "Merging $sid"
    bash scripts/merge_fastqs.sh $IN_DATA $OUT_MERG "$sid" 
done

mkdir -p $LOG_CUT
mkdir -p $OUT_CUT


for sid in $SAMPLES_IDS; 
do 
    echo "Remove adapters with Cutadapt $sid"
    cutadapt \
        -m 18 \
        -a TGGAATTCTCGGGTGCCAAGG \
        --discard-untrimmed \
        -o $OUT_CUT/${sid}.trimmed.fastq.gz $OUT_MERG/${sid}_merged.fastq.gz > $LOG_CUT/${sid}.log
done


# Aligment 

for fname in $OUT_CUT/*.fastq.gz
do
    sid=$(basename "$fname" .trimmed.fastq.gz)
    mkdir -p $OUT_STAR/$sid
    
    if [ ! -f "$OUT_STAR/$sid/Log.final.out" ]; then
        echo "STAR in $sid with $fname"
        STAR --runThreadN $THREADS --genomeDir $CONTA_IDX \
            --outReadsUnmapped Fastx --readFilesIn "$fname" \
            --readFilesCommand gunzip -c --outFileNamePrefix $OUT_STAR/$sid/
    else
        echo "STAR output for $sid already exists. Skipping."
    fi
done

# Create a log file containing information from cutadapt and star logs
# (this should be a single log file, and information should be *appended* to it on each run)
# - cutadapt: Reads with adapters and total basepairs
# - star: Percentages of uniquely mapped reads, reads mapped to multiple loci, and to too many loci

echo "Pipeline run: $(date)" > "$LOG_SUM"

echo "Cutadapt summary:" >> "$LOG_SUM"
for log in $LOG_CUT/*.log; do
    sid=$(basename "$log" .log)
    echo "Sample: $sid" >> "$LOG_SUM"
    grep -E "Reads with adapters|Total basepairs processed" "$log" >> "$LOG_SUM"
done

echo "STAR summary:" >> "$LOG_SUM"
for sid in $SAMPLES_IDS; do
    star_log="$OUT_STAR/$sid/Log.final.out"
    echo "Sample: $sid" >> "$LOG_SUM"
    grep "Uniquely mapped reads %" "$star_log" >> "$LOG_SUM"
    grep "to multiple loci %" "$star_log" >> "$LOG_SUM"
    grep "to too many loci" "$star_log" >> "$LOG_SUM"
    
done

echo "Summary appended to $LOG_SUM"

# REPORT

mkdir -p $OUT_MULTIQC
multiqc -o $OUT_MULTIQC "$(pwd)"