#!/bin/bash 

myplink="/Users/wangxulo/Applications/plink_mac/plink"
mygnetlmm="/Users/wangxulo/Git/GNetLMM/"

cd $mygnetlmm 

BFILE=/Users/wangxulo/Git/GNetLMM/data/1000G_chr22/chrom22_subsample20_maf0.10 # genotype: bed basename
PFILE=/Users/wangxulo/Git/GNetLMM/out/pheno # gene expression: basename
CFILE=/Users/wangxulo/Git/GNetLMM/out/chrom22 # covariance matrix

# compute covariance matrix

./GNetLMM/bin/gNetLMM_preprocess --compute_covariance --plink_path $myplink --bfile $BFILE --cfile $CFILE

FFILE=/Users/wangxulo/Git/GNetLMM/data/1000G_chr22/ones.txt # covariate file
ASSOC0FILE=/Users/wangxulo/Git/GNetLMM/out/lmm # initial association scan

# run initial association scan

./GNetLMM/bin/gNetLMM_analyse --initial_scan --bfile $BFILE --pfile $PFILE --cfile $CFILE.cov --assoc0file $ASSOC0FILE --ffile $FFILE

# run initial association scan in batch

for i in $(seq 0 10000 40000)
do
  ./GNetLMM/bin/gNetLMM_analyse --initial_scan --bfile $BFILE --pfile $PFILE --cfile $CFILE.cov --assoc0file $ASSOC0FILE --startSnpIdx $i --nSnps 10000 --ffile $FFILE
done

./GNetLMM/bin/gNetLMM_analyse --merge_assoc0_scan  --assoc0file $ASSOC0FILE --nSnps 10000 --bfile $BFILE # merging results

GFILE=/Users/wangxulo/Git/GNetLMM/out/genes

# compute marginal gene-gene correlations

./GNetLMM/bin/gNetLMM_analyse --gene_corr --pfile $PFILE --gfile $GFILE

# compute marginal gene-gene correlations in batch

for i in $(seq 0 25 100)
do
  ./GNetLMM/bin/gNetLMM_analyse --gene_corr --pfile $PFILE --gfile $GFILE  --startTraitIdx $i --nTraits 25
done

./GNetLMM/bin/gNetLMM_analyse --merge_corr  --gfile $GFILE  --pfile $PFILE --nTraits 25 # merging results

# compute anchors 

ANCHOR_THRESH=1e-6
ANCHORFILE=./out/cisanchor_thresh1e-6_wnd2000.txt
WINDOW=2000

./GNetLMM/bin/gNetLMM_analyse --compute_anchors  --bfile $BFILE --pfile $PFILE --assoc0file $ASSOC0FILE --anchorfile $ANCHORFILE --anchor_thresh=$ANCHOR_THRESH  --window=$WINDOW --cis

# find v-structures

VFILE=./out/vstructures_thresh1e-6_wnd2000

./GNetLMM/bin/gNetLMM_analyse --find_vstructures --pfile $PFILE --gfile $GFILE --anchorfile $ANCHORFILE --assoc0file $ASSOC0FILE --window $WINDOW --vfile $VFILE --bfile $BFILE

# find v-structures in batch

for i in $(seq 0 10 90)
do
  ./GNetLMM/bin/gNetLMM_analyse --find_vstructures  --pfile $PFILE  --gfile $GFILE --anchorfile $ANCHORFILE  --assoc0file $ASSOC0FILE  --window $WINDOW --vfile $VFILE --bfile $BFILE --startTraitIdx $i --nTraits 10
done

./GNetLMM/bin/gNetLMM_postprocess --concatenate --infiles $VFILE --outfile $VFILE # merging csv files

# update associations

ASSOCFILE=./out/gnetlmm_thresh1e-6_wnd2000

./GNetLMM/bin/gNetLMM_analyse --update_assoc --bfile $BFILE --pfile $PFILE --cfile $CFILE.cov --ffile $FFILE --vfile $VFILE --assocfile $ASSOCFILE

# update associations in batch

for i in $(seq 0 10 90)
do
  ./GNetLMM/bin/gNetLMM_analyse --update_assoc --bfile $BFILE --pfile $PFILE --cfile $CFILE.cov --ffile $FFILE --vfile $VFILE --assocfile $ASSOCFILE --startTraitIdx $i --nTraits 10
done

./GNetLMM/bin/gNetLMM_postprocess --concatenate --infiles $ASSOCFILE  --outfile $ASSOCFILE # merging csv files

# write to matrix
./GNetLMM/bin/gNetLMM_postprocess --merge_assoc --assoc0file $ASSOC0FILE --assocfile $ASSOCFILE

# block associationss

for i in $(seq 0 10 90)
do
  ./GNetLMM/bin/gNetLMM_analyse --block_assoc --bfile $BFILE --pfile $PFILE --cfile $CFILE.cov --ffile $FFILE --vfile $VFILE --assocfile $ASSOCFILE.block --startTraitIdx $i --nTraits 10
done

./GNetLMM/bin/gNetLMM_postprocess --concatenate --infiles $ASSOCFILE.block  --outfile $ASSOCFILE.block # merging csv files

# write to matrix
./GNetLMM/bin/gNetLMM_postprocess --merge_assoc --assoc0file $ASSOC0FILE --assocfile $ASSOCFILE.block

# plot results

PLOTFILE=./out/power.pdf

./GNetLMM/bin/gNetLMM_postprocess --plot_power --assocfile $ASSOCFILE --assoc0file $ASSOC0FILE --plotfile $PLOTFILE --pfile $PFILE --bfile $BFILE --window $WINDOW --blockfile $ASSOCFILE.block

# creating output file for v-structures
./GNetLMM/bin/gNetLMM_postprocess --nice_output --bfile $BFILE --pfile $PFILE --vfile $VFILE --assoc0file $ASSOC0FILE --assocfile $ASSOCFILE --blockfile $ASSOCFILE.block --outfile $ASSOCFILE.nice

