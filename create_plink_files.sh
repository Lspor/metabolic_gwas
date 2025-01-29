#!/bin/bash

#$ -S /bin/bash
#$ -l h_rt=02:00:00
#$ -t 1-23
#$ -cwd
#$ -j yes

set -veuo pipefail

echo "Started create_plink_files script"

# We previously created auxiliary files using `create_auxiliary_files.Rmd`


# path to VCF files
VCF_PATH="/home/mok36/imputation_code/freeze9b/discovery/12_final_merge"


# Data for each chromosome is stored in its own VCF file
# create an exception for chrX in the array

CHR=$SGE_TASK_ID
if [ $CHR == "23" ]; then
    CHR="X"
fi

echo "Processing chromosome $CHR"

# for each chromosome, we need to create filtered VCF files
# our filters including the following criteria:
## 3,119 Samoan participants from the 2010 discovery cohort
## R2 threshold of 0.3 to remove poorly imputed variants
    
echo "Creating filtered VCF file for chromosome $CHR"
bcftools view -i 'INFO/R2>0.3' \
  -S subject_ids.txt \
  $VCF_PATH/discovery-9b-hg38-final-merge-chr${CHR}.dose.vcf.gz \
  -Oz -o ~/shared_data/plink/discovery_hg38_chr${CHR}.vcf.gz
  
  
# Next, we use the filtered VCF files to create PLINK Bfiles
## here, we remove monomorphic variants (MAF < 0.0001)
## add sex information
## and calculate LD for each file

echo "Creating filtered PLINK bfiles for chromosome $CHR"
plink --vcf ~/shared_data/plink/discovery_hg38_chr${CHR}.vcf.gz \
  --maf 0.0001 \
  --update-sex update_sex.txt \
  --r2 --ld-window 99999 --ld-window-r2 0.05 \
  --make-bed \
  --out ~/shared_data/plink/discovery_hg38_chr${CHR}


# create PLINK files without rsIDs for COJO pipeline
sed 's/;rs[0-9]*//g' discovery_hg38_chr${CHR}.bim > plink_no_rsID/discovery_hg38_no_rsID_chr${CHR}.bim
cp discovery_hg38_chr${CHR}.fam plink_no_rsID/discovery_hg38_no_rsID_chr${CHR}.fam
cp discovery_hg38_chr${CHR}.bed plink_no_rsID/discovery_hg38_no_rsID_chr${CHR}.bed

# zip LD files to save space
gzip discovery_hg38_chr${CHR}.ld

# Lastly, remove the intermediate VCF file to save space
rm ~/shared_data/plink/discovery_hg38_chr${CHR}.vcf.gz

echo "Completed processing chromosome $CHR"