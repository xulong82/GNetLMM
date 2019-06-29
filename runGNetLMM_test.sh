#!/bin/bash 

cd ~/Git/GNetLMM/

BFILE=/Users/wangxulo/Git/GNetLMM/data/1000G_chr22/chrom22_subsample20_maf0.10 # specify here bed basename
PFILE=/Users/wangxulo/Git/GNetLMM/out/pheno

# Generate phenotypes
./GNetLMM/bin/gNetLMM_simPheno --bfile $BFILE --pfile $PFILE

CFILE=/Users/wangxulo/Git/GNetLMM/out/chrom22

myplink=/Users/wangxulo/Applications/plink_mac/plink

# Compute covariance matrix
./GNetLMM/bin/gNetLMM_preprocess --compute_covariance --plink_path $myplink --bfile $BFILE --cfile $CFILE

FFILE=/Users/wangxulo/Git/GNetLMM/data/1000G_chr22/ones.txt
ASSOC0FILE=/Users/wangxulo/Git/GNetLMM/out/lmm

# Run initial association scan

./GNetLMM/bin/gNetLMM_analyse --initial_scan --bfile $BFILE --pfile $PFILE --cfile $CFILE.cov --assoc0file $ASSOC0FILE --ffile $FFILE

# in batch
for i in $(seq 0 10000 40000)
do
    ./GNetLMM/bin/gNetLMM_analyse --initial_scan --bfile $BFILE --pfile $PFILE --cfile $CFILE.cov --assoc0file $ASSOC0FILE --startSnpIdx $i --nSnps 10000 --ffile $FFILE
done

# Merging results
./GNetLMM/bin/gNetLMM_analyse --merge_assoc0_scan  --assoc0file $ASSOC0FILE --nSnps 10000 --bfile $BFILE

GFILE=/Users/wangxulo/Git/GNetLMM/out/genes

# Compute marginal gene-gene correlations

./GNetLMM/bin/gNetLMM_analyse --gene_corr --pfile $PFILE --gfile $GFILE

# in batch
for i in $(seq 0 25 100)
do
./GNetLMM/bin/gNetLMM_analyse --gene_corr --pfile $PFILE --gfile $GFILE  --startTraitIdx $i --nTraits 25
done

# Merging results
./../GNetLMM/bin/gNetLMM_analyse --merge_corr  --gfile $GFILE  --pfile $PFILE --nTraits 25

# Compute anchors 

ANCHOR_THRESH=1e-6
ANCHORFILE=./out/cisanchor_thresh1e-6_wnd2000.txt
WINDOW=2000

./GNetLMM/bin/gNetLMM_analyse --compute_anchors  --bfile $BFILE --pfile $PFILE --assoc0file $ASSOC0FILE --anchorfile $ANCHORFILE --anchor_thresh=$ANCHOR_THRESH  --window=$WINDOW --cis

# Find v-structures

VFILE=./out/vstructures_thresh1e-6_wnd2000

./GNetLMM/bin/gNetLMM_analyse --find_vstructures --pfile $PFILE --gfile $GFILE --anchorfile $ANCHORFILE --assoc0file $ASSOC0FILE --window $WINDOW --vfile $VFILE --bfile $BFILE

# in batch
for i in $(seq 0 10 90)
do
    ./GNetLMM/bin/gNetLMM_analyse --find_vstructures  --pfile $PFILE  --gfile $GFILE --anchorfile $ANCHORFILE  --assoc0file $ASSOC0FILE  --window $WINDOW --vfile $VFILE --bfile $BFILE --startTraitIdx $i --nTraits 10
done

# Merging csv files
./GNetLMM/bin/gNetLMM_postprocess --concatenate --infiles $VFILE      --outfile $VFILE

# Update associationss

ASSOCFILE=./out/gnetlmm_thresh1e-6_wnd2000

./GNetLMM/bin/gNetLMM_analyse --update_assoc --bfile $BFILE --pfile $PFILE --cfile $CFILE.cov --ffile $FFILE --vfile $VFILE --assocfile $ASSOCFILE

for i in $(seq 0 10 90)
do
     ./GNetLMM/bin/gNetLMM_analyse --update_assoc --bfile $BFILE --pfile $PFILE --cfile $CFILE.cov --ffile $FFILE --vfile $VFILE --assocfile $ASSOCFILE --startTraitIdx $i --nTraits 10
done

# Merging csv files
./GNetLMM/bin/gNetLMM_postprocess --concatenate --infiles $ASSOCFILE  --outfile $ASSOCFILE

# Write to matrix
./GNetLMM/bin/gNetLMM_postprocess --merge_assoc --assoc0file $ASSOC0FILE --assocfile $ASSOCFILE

# Block associationss
for i in $(seq 0 10 90)
do
     ./GNetLMM/bin/gNetLMM_analyse --block_assoc --bfile $BFILE --pfile $PFILE --cfile $CFILE.cov --ffile $FFILE --vfile $VFILE --assocfile $ASSOCFILE.block --startTraitIdx $i --nTraits 10
done

# Merging csv files
./GNetLMM/bin/gNetLMM_postprocess --concatenate --infiles $ASSOCFILE.block  --outfile $ASSOCFILE.block

# Write to matrix
./GNetLMM/bin/gNetLMM_postprocess --merge_assoc --assoc0file $ASSOC0FILE --assocfile $ASSOCFILE.block

# Plot results

PLOTFILE=./out/power.pdf

./GNetLMM/bin/gNetLMM_postprocess --plot_power --assocfile $ASSOCFILE --assoc0file $ASSOC0FILE --plotfile $PLOTFILE --pfile $PFILE --bfile $BFILE --window $WINDOW --blockfile $ASSOCFILE.block

# Creating nice output file for v-structures
./GNetLMM/bin/gNetLMM_postprocess --nice_output --bfile $BFILE --pfile $PFILE --vfile $VFILE --assoc0file $ASSOC0FILE --assocfile $ASSOCFILE --blockfile $ASSOCFILE.block --outfile $ASSOCFILE.nice

