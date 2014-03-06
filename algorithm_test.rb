#encoding: utf-8
require_relative 'lib/reform_ratio'
require_relative 'lib/GATOC'

if ARGV[0] == nil || ARGV[1] == nil
	puts 'Wrong number of command line arguments! Specify a dataset and test-set'
else

	vcf_file = "arabidopsis_datasets/#{ARGV[0]}/snps.vcf"
	fasta_file = "arabidopsis_datasets/#{ARGV[0]}/frags_shuffled.fasta"

	ordered_fasta_file = "arabidopsis_datasets/#{ARGV[0]}/frags.fasta"
	ordered_fasta = ReformRatio::fasta_array(ordered_fasta_file)

	#GATOC::evolve(fasta_file, vcf_file, ordered_fasta, :gen => 1, :pop_size => 20, :select_num => 10, :mut_num => 2, :save => 1, :ran => 1, :figures => 'figures')

	GATOC::evolve(fasta_file, vcf_file, ordered_fasta, :gen => 1000000)
end
