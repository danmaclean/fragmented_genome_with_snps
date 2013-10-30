Rearrangement methods part 2
========================================================

Having created a new dataset ([dataset2](https://github.com/edwardchalstrey1/fragmented_genome_with_snps/blob/master/writeup/dataset2.md)), I will re-run the existing fragment rearrangement methods described in [rearrangement_methods.md](https://github.com/edwardchalstrey1/fragmented_genome_with_snps/blob/master/writeup/rearrangement_methods.md). I will then continue to write up additional experiments here. I used this [fasta](https://github.com/edwardchalstrey1/fragmented_genome_with_snps/blob/master/fasta_vcf_d2/frags_shuffled.fasta) and this [VCF](https://github.com/edwardchalstrey1/fragmented_genome_with_snps/blob/master/fasta_vcf_d2/snps.vcf). Whilst dataset 1 contained 1310 fragments, dataset 2 contains 1321. 

Existing Method Scores
----------------------

Below are a list of the methods used in [rearrangement_methods.md](https://github.com/edwardchalstrey1/fragmented_genome_with_snps/blob/master/writeup/rearrangement_methods.md), and a table comparing the scores for dataset 1 and 2:

Highest possible score (C0), Density order Score (C1), Random Score (C2), Even Odd Method Score (M1a), Odd Even Method Score (M1b), Left Right Method Score (M2a), Left Right Density Method Score (M2b)

![Image](https://github.com/edwardchalstrey1/fragmented_genome_with_snps/blob/master/figures/dataset_scores_table.png?raw=true)
[Figure 1](https://github.com/edwardchalstrey1/fragmented_genome_with_snps/blob/master/figures/dataset_scores_table.png)

As you can see from Figure 1, for each rearrangement method, the ordinal similarity score is similar in both datasets (and slightly higher for dataset 2 in most cases, probably due to the larger number of fragments). This was what I expected for the controls and method 1 (odd/even), since the change in the model genome was aimed at maximising the potential of method 2b (left right density), see [dataset2](https://github.com/edwardchalstrey1/fragmented_genome_with_snps/blob/master/writeup/dataset2.md). This method relies on the skew of SNPs to determine each fragments position in the rearranged order, see [rearrangement_methods.md](https://github.com/edwardchalstrey1/fragmented_genome_with_snps/blob/master/writeup/rearrangement_methods.md).

Figure 1 also shows that method 2b has a similar ordinal similarity score for both datasets. What this may suggest is that the skew of SNPs on a fragment is in fact not a good indicator of its position in the genome. However, it could be that the current skew method (2b) is simply incorrect in its placing of the fragments. 