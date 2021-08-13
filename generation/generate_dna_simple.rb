require 'csv'
require 'yaml'
require 'set'

N = 10000
TRAITS_DISTRIBUTION_FILE = 'traits_config.yml'
DNA_FILE = 'dna.csv'

raw_traits = YAML.load_file(TRAITS_DISTRIBUTION_FILE)['traits']
trait_probabilities = raw_traits.transform_values { |dist_h| dist_h.map { |k,v| [k]*v.to_i }.flatten }

# verify that size of all probabilities is 100
if trait_probabilities.values.map{|v| v.size%100 }.uniq != [0]
  error_traits = trait_probabilities.select{ |k,v| v.size%100 != 0 }
  raise "Probabilities for these dont match to 100, #{error_traits}"
end

dna_set = Set.new()
serial = 0

CSV.open(DNA_FILE, "w") do |csv|
  # write headers
  csv << (['serial'] + trait_probabilities.keys + ['dna'])

  # write N unique dna's
  loop do
    traits = trait_probabilities.values.map(&:sample)
    dna = traits.join('--')

    unless dna_set.include?(dna)
      csv << [serial] + traits + [dna]
      dna_set.add(dna)
      serial += 1
      break if serial == N
    end
  end
end
