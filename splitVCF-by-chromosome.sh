#! /bin/bash


module load bcftools/1.3.1
module load tabix

cd /home/groups/hpcbio_shared/azza/H3A_NextGen_assessment_set3/data/genome

: << 'comment_block'
# Generating a vcf.gz file if not already present:
bgzip -c 1000G_phase1.indels.hg19.sites.vcf > 1000G_phase1.indels.hg19.sites.vcf.gz
tabix -p vcf 1000G_phase1.indels.hg19.sites.vcf.gz

bgzip -c Mills_and_1000G_gold_standard.indels.hg19.sites.vcf > Mills_and_1000G_gold_standard.indels.hg19.sites.vcf.gz 
tabix -p vcf Mills_and_1000G_gold_standard.indels.hg19.sites.vcf.gz

# Splitting up the reference by chromosome/ contig:

cut -f1 ucsc.hg19.fasta.fai | xargs -i echo tabix 1000G_phase1.indels.hg19.sites.vcf.gz {} \| bgzip \> IndelsByChr/1000G.{}.vcf.gz \&|sh
cut -f1 ucsc.hg19.fasta.fai | xargs -i echo tabix Mills_and_1000G_gold_standard.indels.hg19.sites.vcf.gz {} \| bgzip \> IndelsByChr/Mills.{}.vcf.gz \&|sh

# It wasn't necessary to gzip the files in the last step, so I'm unzipping here!!!
ls IndelsByChr/* >list
readarray chrs < list
rm list

for file in "${chrs[@]}" ; do
	bgzip -d ${file}
done 

# Now, add the header to the 1000G vcf files:
ls IndelsByChr/1000G*vcf> list
readarray chrs < list
rm list
 
for file in "${chrs[@]}" ; do
	bcftools view -h 1000G_phase1.indels.hg19.sites.vcf.gz > header.txt
	cat header.txt ${file} > tmp.vcf 
	mv tmp.vcf ${file}
done
comment_block

# Now, add the header to the Mills vcf files:
ls IndelsByChr/Mills* > list
readarray chrs < list
rm list

for file in "${chrs[@]}" ; do
	bcftools view -h Mills_and_1000G_gold_standard.indels.hg19.sites.vcf.gz  > header.txt
	cat header.txt ${file} > tmp.vcf
	mv tmp.vcf ${file}
done

rm header.txt tmp.vcf

module unload bcftools/1.3.1
module unload tabix
