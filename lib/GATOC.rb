#encoding: utf-8
class GATOC # Genetic Algorithm To Order Contigs

	require 'rubygems'
	require 'bio-samtools'
	require 'bio'
	require 'rinruby'
	require_relative 'write_it'
	require_relative 'reform_ratio'
	require_relative 'rearrangement_score'

	myr = RinRuby.new(echo = false)
	myr.eval "source('~/fragmented_genome_with_snps/lib/comparable_ratio.R')"
	RATIO = myr.pull "comparable_ratio(1)" # this is the same for every instance of the class
	myr.quit

	# Input: Array
	# Output: A random integer that the length of the Input 0 array can be divided by to get another integer (the randomly chosen size of chunks that permutations will be split into, in the recombine/mutate methods)
	def self.division(frags) #number of frags must be > 10
		x = 1.5
		until frags.length/x == (frags.length/x).to_i && x == x.to_i && x < frags.length
			x = (frags.length/10).to_f + rand(frags.length).to_f
		end
		return x
	end

	# Input 0: A parent permutation array of Bio::FastaFormat entries (or any array of unique objects)
	# Input 1: A second parent permutation array of Bio::FastaFormat entries (or any array of the same unique objects as input 0)
	# Output: A child permutation array of Bio::FastaFormat entries, whose order is a recombination of the parent permutations (the same unique objects ordered differently to either input)
	def self.recombine(a_parent, b_parent)
		kid = []
		1.times do # so we can use redo
			x = division(a_parent)
			if x == a_parent.length && WriteIt::prime?(x) == false # If a dataset with a non-prime number of fragments comes up with x == fragment length, redo
				redo
			elsif x == a_parent.length # to compensate for datasets with a prime number of fragments:
				ig = rand(a_parent.length)-1 # choose a random element of the fasta array to ignore # we can add the frag at this element back at its original position after recombination
				a_parent_reduced = a_parent.dup.delete_at(ig)
				b_parent_reduced = b_parent.dup.delete_at(ig)
				x = division(a_parent_reduced)
				a_parent_sliced = a_parent_reduced.each_slice(x).to_a
				b_parent_sliced = b_parent_reduced.each_slice(x).to_a
			else
				a_parent_sliced = a_parent.each_slice(x).to_a
				b_parent_sliced = b_parent.each_slice(x).to_a
			end
			chosen = rand(b_parent_sliced.length)-1 # choose one of the chunks of fragments to keep from b_parent
			child = a_parent.dup
			y = 0
			pos_array = []
			a_parent_sliced[chosen].each do |frag| # place each frag in the equivalent a_parent chunk into the position it's corresponding frag (from b_parent) occupies in a_parent
				chunk_frag = b_parent_sliced[chosen][y] # the equivalent frag in the chosen b_parent chunk
				pos = a_parent_sliced.flatten.index(chunk_frag) # the position of the b_parent chunk frag in a_parent
				c_pos = a_parent_sliced.flatten.index(frag) # the position of the frag in a_parent
				pos_array << pos
				y+=1
			end
			if pos_array.include?(nil)
				redo
			else
				y = 0
				pos_array.each do |pos|
					unless b_parent_sliced[chosen].include?(a_parent_sliced[chosen][y])
						child[pos] = a_parent_sliced[chosen][y]
						child[a_parent_sliced.flatten.index(a_parent_sliced[chosen][y])] = b_parent_sliced[chosen][y] # swapping the positions of the frag and chunk frag, to give their positions in child
					end
					y+=1
				end
			end
			if ig != nil
				if b_parent_sliced[chosen].include?(b_parent[ig]) # add the ignored fragment from b_parent if it's in the chosen chunk...
					child.insert(ig, b_parent[ig])
				else
					child.insert(ig, a_parent[ig]) # ...otherwise add the ignored fragment from a_parent
				end
			end
			if child != child.uniq
				redo
			end
			kid << child #so we can access this outside the loop
		end
		return kid[0]
	end

	# Input: A permutation array of Bio::FastaFormat entries (or any array)
	# Output: The input permutation array of Bio::FastaFormat entries, with a small change in the fragment order
	def self.mutate(fasta)
		mutant = []
		1.times do
			x = 0
			until x > 2
				x = division(fasta)
			end
			sliced = fasta.each_slice(x).to_a
			e = rand(sliced.length-1).to_i
			sliced[e] = sliced[e].shuffle
			if sliced.flatten == fasta
				redo
			end
			mutant << sliced.flatten
		end
		return mutant[0]
	end

	# Input: A permutation array of Bio::FastaFormat entries (or any array)
	# Output: The input permutation array of Bio::FastaFormat entries, with a small change in the fragment order
	def self.mini_mutate(fasta)
		a = b = 0
		until a != b
			a = fasta[rand(fasta.length-1)]
			b = fasta[rand(fasta.length-1)]
		end
		mutant = []
		fasta.each do |i|
			if i == a
				mutant << b
			elsif i == b
				mutant << a
			else
				mutant << i
			end
		end
		return mutant
	end

	# Input 0: A permutation array of Bio::FastaFormat entries (fragment arrangement)
	# Input 1: Array of all the outputs from get_snp_data method
	# Input 2: "same" if we wish to compare the reformed ratio to the constant RATIO, or any other argument if we wish to compare to a re-run of comparable_ratio function in comparable_ratio.R
	# Output: A correlation value that is the fitness of the Input 0 permutation
	def self.fitness(fasta, snp_data, same)
		snps_per_frag = ReformRatio::snps_per_fasta_frag(snp_data[2], fasta) #array of no. of snps per frag in same order as fasta
		pos_n_info = ReformRatio::get_positions(fasta, snp_data[0], snp_data[1], snps_per_frag, snp_data[3]) #get snp positions for each frag in array of arrays
		actual_pos = ReformRatio::total_pos(pos_n_info[0], ReformRatio::fasta_id_n_lengths(fasta)[1])
		het_hom_snps = ReformRatio::het_hom(actual_pos, pos_n_info[1])
		myr = RinRuby.new(echo = false)
		myr.assign 'het_snps', het_hom_snps[0]
		myr.assign 'hom_snps', het_hom_snps[1]
		myr.eval "source('~/fragmented_genome_with_snps/lib/comparable_ratio.R')"
		if same == 'diff'
			ratio = myr.pull 'comparable_ratio(1)'
		else
			ratio = RATIO
		end
		myr.assign 'ratio', ratio
		myr.eval 'correlation <- get_corr(het_snps, hom_snps, ratio)'
		return myr.pull 'correlation'
		if same == 'figure'
			myr.assign 'dataset', ARGV[0]
			myr.eval 'real_ratio <- get_real_ratio(het_snps, hom_snps, ratio)'
			myr.eval 'plot_distribution(real_ratio, dataset)' # plot of the real_ratio
		end
		myr.quit
	end

	# Input 0: Array of Bio::FastaFormat entries (or any array)
	# Input 1: Integer of the desired population size
	# Output: Population - Array of size "size", where each element is a shuffled permutation of the input 0 array of Bio::FastaFormat entries (random permutations)
	def self.initial_population(fasta, size)
		population = []
		size.times do
			chromosome = fasta.shuffle
			population << chromosome
		end
		return population
	end

	# Input 0: Population - array of arrays where each sub array is a permutation of the fragments (Bio::FastaFormat entries)
	# Input 1: Array of all the outputs from get_snp_data method
	# Input 2: Integer of the desired number of permutations to be selected for the next generation
	# Output 1: Array of fittest selection of Input 0 population: each sub array has two elements, the fitness and the permutation (which is itself an array of fragments)
	# Output 2: Integer of leftover fragments, to be taken from the multiplied selected population
	def self.select(pop, snp_data, num)
		fits = []
		pop.each do |fasta_array|
			fits << fitness(fasta_array, snp_data, "same")
		end
		pop_fits = fits.zip(pop).sort
		initial_size = pop_fits.size
		sliced = pop_fits.reverse.each_slice(num).to_a
		pop_fits = sliced[0].reverse
		if sliced[-1].length != sliced[0].length # if there is a remainder slice
			leftover = sliced[-1].length
		else 
			leftover = 0
		end
		puts "Selected #{pop_fits.size} of #{initial_size} permutations"
		return pop_fits, leftover
	end

	# Input 0: Array of fittest selection of previous population: each sub array has two elements, the fitness and the permutation (which is itself an array of fragments)
	# Input 1: Integer of the desired population size
	# Input 2: Integer of the desired number of mutant permutations in the new population (this number of mutate and mini_mutate methods)
	# Input 3: Integer of the desired number of the best permutations from the previous population, to be included in the new one
	# Input 4: Integer of the desired number of randomly shuffled permutations in a new population
	# Input 5: Integer of the number of permutations selected by the select method
	# Input 6: Integer of leftover fragments, to be taken from the multiplied selected population
	# Output: New population of mutants, recombinants etc - array of arrays where each sub array is a permutation of the fragments (Bio::FastaFormat entries)
	def self.new_population(pop_fits, size, mut_num, save, ran, select_num, leftover) # mut_num = no. of mutants, save = number saved; from best, ran = no. of random permutations
		x = (size-leftover)/select_num
		pop_fits = pop_fits*x
		if leftover != 0
			pop_fits = [pop_fits, pop_fits[-leftover..-1]].flatten(1) #add leftover number of frags (best)
		end
		pop_save = pop_fits.reverse.each_slice(save).to_a[0] # saving best "save" of permutations
		pop = []
		pop_save.each{|i| pop << i[1]} # adding the permutations only, not the fitness score
		for i in pop_fits[(mut_num*2)+save+ran..-1]
			x = rand(size-1)
			pop << recombine(i[1], pop_fits[x][1])
		end
		mut_num.times{pop << mutate(pop_fits[rand(pop_fits.length)][1])} # mutating randomly selected permutations from pop_fits
		mut_num.times{pop << mini_mutate(pop_fits[-1][1])} # mini_mutating the best permutations
		ran.times{pop << pop_fits[0][1].shuffle}
		puts "New population size = #{pop.size}, with #{size - ((mut_num * 2) + save + ran)} recombinants, #{mut_num} mutants, #{mut_num} mini_mutants, the #{save} best from the previous generation and #{ran} random permutations."
		return pop
	end

	# Input 0: A permutation array of Bio::FastaFormat entries
	# Input 1: VCF file
	# Input 2: Integer of the number of times the fitness method should be called with the permutation, and to divide the sum by to get an average
	# Output: Average fitness correlation value
	def self.average_fitness(fasta, vcf_file, num)
		snp_data = get_snp_data(vcf_file)
		fits = []
		num.times do
			fits << fitness(fasta, snp_data, "diff")
		end
		worst = fits.sort[0]
		average = fits.inject(:+)/num
		puts "Worst #{worst}"
		puts "Average #{average}"
		return average
	end

	# Input 0: FASTA file
	# Input 1: VCF file
	# Input 2: Correctly ordered array of Bio::FastaFormat entries
	# Input 3: parameters:
		# gen: Integer of desired number of generations - the number of times a new population is created from an old one
		# pop_size: Integer of desired size of each population (array of arrays where each sub array is a permutation of the fragments (Bio::FastaFormat entries))
		# mut_num: Integer of the desired number of mutant permutations in each new population (this number of mutate and mini_mutate methods)
		# save: Integer of the desired number of the best permutations from each population, to be included in the next one
		# ran: Integer of the desired number of randomly shuffled permutations in each new population
	# Output 1: A saved .txt file of the fragment identifiers, of a permutation with a fitness that suggests it is the correct order
	# Output 2: A saved figure of the algorithm's performance
	# Output 3: A saved figure of the best permuation's homozygous/heterozygous SNP density ratio across the genome, assuming the fragment permutation is correct
	def self.evolve(fasta_file, vcf_file, ordered_fasta, parameters)
		opts = {
			:gen => 200,
			:pop_size => 100,
			:select_num => 50,
			:mut_num => 10,
			:save => 5,
			:ran => 5,
			:figures => 'figures'
			}.merge!(parameters)

		gen_fits = [] # array of the best fitness in each generation
		ordered_ids = ReformRatio::fasta_id_n_lengths(ordered_fasta)[0]
		snp_data = ReformRatio::get_snp_data(vcf_file) #array of vcf frag ids, snp positions (fragments with snps), hash of each frag from vcf with no. snps, array of info field
		puts "Original order correlation = #{fitness(ordered_fasta, snp_data, "same")}\n \nGen 0"
		fasta = ReformRatio::fasta_array(fasta_file) #array of fasta format fragments
		pop = initial_population(fasta, opts[:pop_size])
		pop_fits_n_leftover = select(pop, snp_data, opts[:select_num])
		pop_fits = pop_fits_n_leftover[0]
		leftover = pop_fits_n_leftover[1]
		best_perm = pop_fits[-1][1]
		puts "Best correlation = #{pop_fits[-1][0]}\n"
		gen_fits << pop_fits[-1][0]
		best_perm_ids = ReformRatio::fasta_id_n_lengths(best_perm)[0]
		y=1
		z=1
		opts[:gen].times do
			prev_best_arr = pop_fits[-1][1]
			prev_best_fit = pop_fits[-1][0]
			puts "Gen#{y}"
			pop = new_population(pop_fits, opts[:pop_size], opts[:mut_num], opts[:save], opts[:ran], opts[:select_num], leftover)
			pop_fits_n_leftover = select(pop, snp_data, opts[:select_num])
			pop_fits = pop_fits_n_leftover[0]
			leftover = pop_fits_n_leftover[1]
			best_perm = pop_fits[-1][1]
			puts "Best correlation = #{pop_fits[-1][0]}"
			gen_fits << pop_fits[-1][0]
			best_perm_ids = ReformRatio::fasta_id_n_lengths(best_perm)[0]
			if pop_fits[-1][0] <= prev_best_fit
				puts "No fitness improvement\n \n" # If this is not called, this implies there has been some improvement
				z+=1
			else
				puts "FITNESS IMPROVEMENT!\n \n"
				z=1
			end
			if z >= 10
				puts "Algorithm quit for lack of fitness improvement, rearrangement score of #{RearrangementScore::rearrangement_score(ordered_ids, best_perm_ids)}"
				WriteIt::write_txt("arabidopsis_datasets/#{ARGV[0]}/reformed_ratio_frag_order", best_perm_ids)
				fitness(best_perm, snp_data, "figure") # makes figure of ratio density distribution
			end
			if pop_fits[-1][0] >= 0.995 # If it looks like we have a winner, IN THE FINISHED ALGORITHM, THIS SHOULD BE...
				av = average_fitness(pop_fits[-1][1], vcf_file, 10)
				if av >= 0.999 && figures != 'no figures'
					puts "Fitness #{av}: reform ratio has a rearrangement score of #{RearrangementScore::rearrangement_score(ordered_ids, best_perm_ids)}"
					WriteIt::write_txt("arabidopsis_datasets/#{ARGV[0]}/reformed_ratio_frag_order", best_perm_ids)
					fitness(best_perm, snp_data, "figure") # makes figure of ratio density distribution
					z = 10
				end
			end
			if z >= 10
				then break
			end
			y+=1
			Signal.trap("PIPE", "EXIT")
		end
		if figures != "no figures"
			myr = RinRuby.new(echo=false)
			myr.assign "gen_fits", gen_fits
			myr.eval "source('~/fragmented_genome_with_snps/lib/comparable_ratio.R')"
			myr.assign "dataset", ARGV[0]
			myr.eval "plot_performance(gen_fits, dataset)"
			myr.quit
		end
	end
end