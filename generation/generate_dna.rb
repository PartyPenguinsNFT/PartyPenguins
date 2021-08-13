require 'csv'
require 'yaml'
require 'set'

N = 10000
TRAITS_FILE = 'traits_config.yml'
DNA_FILE = 'dna.csv'

FACE_COVERING_HATS = ['hat20', 'hat21', 'hat24', 'hat40', 'hat41', 'hat42', 'hat49', 'hat55', 'hat56', 'hat57', 'hat58', 'hat59', 'hat60', 'hat61', 'hat78', 'hat80']
ALL_EYES = (1..31).map{|i| "Eye#{format('%02d', i)}"}
EXTENDING_EYES = ['Eye26', 'Eye27', 'Eye28', 'Eye29', 'Eye09', 'Eye13']

raw_traits = YAML.load_file(TRAITS_FILE)['traits']
trait_probabilities = raw_traits.transform_values { |dist_h| dist_h.map { |k,v| [k]*v.to_i }.flatten }

# verify that size of all probabilities is 100
if trait_probabilities.values.map{|v| v.size%100 }.uniq != [0]
  error_traits = trait_probabilities.select{ |k,v| v.size%100 != 0 }
  raise "Probabilities for these dont match to 100, #{error_traits}"
end

dna_set = Set.new()
serial = 0

def face_condition(traits)
  traits['05face'] != 'NONE' && !(['Eye01', 'Eye02', 'Eye03', 'Eye04', 'Eye06', 'Eye07', 'Eye08', 'Eye10', 'Eye12', 'Eye20'].include?(traits['03eye']))
end

def laser_condition(traits)
  traits['03eye'] == 'Eye09' && (['hat78', 'hat61', 'hat55', 'hat56', 'hat57', 'hat58', 'hat59', 'hat60', 'hat51', 'hat50', 'hat46', 'hat41', 'hat40', 'hat42', 'hat36', 'hat20', 'hat21', 'hat24'].include?(traits['06hat']))
end

def raincoat_condition(traits)
  traits['07clothes'] == 'clothes03' && traits['06hat'] != 'NONE'
end

def vr_glasses_condition(traits)
  traits['03eye'] == 'Eye31' && traits['06hat'] != 'NONE'
end

def beak_condition(traits)
  ['Beak05', 'Beak08', 'Beak10', 'Beak09'].include?(traits['04beak']) && traits['05face'] != 'NONE'
end

CSV.open(DNA_FILE, "w") do |csv|
  # write headers
  csv << (['serial'] + trait_probabilities.keys + ['dna'])

  # write N unique dna's
  loop do
    traits = trait_probabilities.map { |k,v| [k, v.sample] }.to_h

    # FACE CONDITION
    next if face_condition(traits)

    # LASER CONDITION
    next if laser_condition(traits)

    # RAINCOAT CONDITION
    next if raincoat_condition(traits)

    # BAGHEAD BOXHEAD CONDITION
    if (traits['06hat'] == 'hat36' || traits['06hat'] == 'hat40')
      traits['03eye'] = 'Eye03'
      traits['07clothes'] = ['clothes15', 'clothes16', 'NONE'].sample
    end

    # BEAK CONDITION
    next if beak_condition(traits)

    # HAT FILTERS
    if FACE_COVERING_HATS.include?(traits['06hat'])
      traits['03eye'] = (ALL_EYES - EXTENDING_EYES).sample
    end

    traits = traits.values
    dna = traits.join('--')

    unless dna_set.include?(dna)
      csv << [serial] + traits + [dna]
      dna_set.add(dna)
      serial += 1
      break if serial == N
    end
  end
end
