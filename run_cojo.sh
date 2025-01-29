#!/bin/bash

#$ -S /bin/bash
#$ -l h_rt=00:30:00
#$ -l h_vmem=16G
#$ -t 1-3
#$ -cwd
#$ -j yes

set -veuo pipefail

# change the directory to the folder with your documents

cd /home/lms288/metabolic_gwas/cojo/homair/

# change the -t argument above to be 1-N, where N is the number of rows in "cojo_df.txt"

# below is the function to run cojo
# change parameters as needed

run_cojo() {

  # Assign variables
  CHR=$1
  MA_FILE=$2
  COND_SNPLIST=$3
  OUTPUT_FILE=$4

  PLINK_FILE="/home/lms288/shared_data/plink/plink_no_rsID/discovery_hg38_no_rsID_chr${CHR}"

  # run COJO

  gcta --bfile $PLINK_FILE \
       --chr $CHR \
       --maf 0.01 \
       --cojo-file $MA_FILE \
       --cojo-cond $COND_SNPLIST \
       --cojo-wind 10000 \
       --cojo-collinear 0.9 \
       --diff-freq 0.5 \
       --cojo-gc \
       --out $OUTPUT_FILE
}

# run cojo for each line in "cojo_df.txt"

run_cojo $(sed -n ${SGE_TASK_ID}p "cojo_df.txt")