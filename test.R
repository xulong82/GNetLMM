# toy data from the tool

options(stringsAsFactors = F)

# covariate file
cfile = "~/Git/GNetLMM/data/1000G_chr22/ones.txt"
cfile = read.csv(cfile, header = F)
table(cfile$V1)

# fam file: sample information file accompanying a .bed binary genotype table
ffile = "~/Git/GNetLMM/data/1000G_chr22/chrom22_subsample20_maf0.10.fam"
ffile = read.csv(ffile, sep = " ", header = F)
head(ffile)

table(ffile$V5)
table(ffile$V6)

# bim file: extended variant information file accompanying a .bed binary genotype table 
ifile = "~/Git/GNetLMM/data/1000G_chr22/chrom22_subsample20_maf0.10.bim"
ifile = read.csv(ifile, sep = "\t", header = F)
head(ifile)

# sample data summary: 274 samples and 49008 variants in chr 22

# what is the model to generate gene expression data?

# they use realized relatedness matrix for covariance matrix
