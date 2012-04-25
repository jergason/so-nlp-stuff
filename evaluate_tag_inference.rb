$LOAD_PATH.unshift '.'
require 'infer_tags'
require 'mallet_tag_utils'
require 'user_comparer'
#require 'user_comparer'

include TagInferencer::MalletUtils
include TagInferencer::TagMetrics

def convert_tags_array_to_count_hashes(tags)
  count_hash = {}
  tags.each do |tag|
    count_hash[tag] = 1
  end
  count_hash
end

def get_kl_divergence(tags_a, tags_b)
  ta = convert_tags_array_to_count_hashes tags_a
  tb = convert_tags_array_to_count_hashes tags_b
  kl_divergence ta, tb
end

def get_count_comparison(tags_a, tags_b)
  ta = convert_tags_array_to_count_hashes tags_a
  tb = convert_tags_array_to_count_hashes tags_b
  simple_count_compare ta, tb
end

def contains_at_least_one_same_key?(tags_a, tags_b)
  ta = convert_tags_array_to_count_hashes tags_a
  tb = convert_tags_array_to_count_hashes tags_b
  simple_count_compare(ta, tb) > 0.0
end

def print_summary_stats(stats)
  average_with_one_tag_in_common = nil
  average_kl_divergence = stats.inject(0.0) { |memo, stat| memo + stat[1][:kl_divergence][0] + stat[1][:kl_divergence][1] } / (stats.length / 2.0)
  average_common = stats.inject(0.0) { |memo, stat| memo + stat[1][:count_comparison] } / stats.length.to_f
  proportion_with_one_shared_tag = stats.select { |doc, stat| stat[:have_shared_tag] }.length / stats.length.to_f
  puts "Average KL Divergence: #{average_kl_divergence}"
  puts "Average proportion of common tags: #{average_common}"
  puts "Proportion with at least one tag in common: #{proportion_with_one_shared_tag} (#{stats.length.to_f * proportion_with_one_shared_tag} out of #{stats.length})"
end

def evaluate_tag_inference(original_data_directory, inference_model, mallet_path, topic_tags_path, data_dir)
  # Step 1: get tags inferred
  inferencer = TagInference::Inferencer.new mallet_path, inference_model, topic_tags_path
  inferred_tags_per_doc = inferencer.infer_tags_for_document data_dir
  source_docs = {}
  stats = {}

  inferred_tags_per_doc.each do |doc, tags|

    #binding.pry
    original_filename = get_filename_to_load_from_mallet_document_name doc
    original_filename = File.join original_data_directory, original_filename
    if source_docs[original_filename].nil?
      source_docs[original_filename] = load_and_parse_question_or_answer_file doc, original_data_directory
    end

    actual_tags = get_tags_for_document doc, source_docs[original_filename]

    # Use KL-Divergence and simple count compare

    # Step 2: for each inferred tag distribution:
    # load the required document
    # compare inferred tags to actual tags
    kl_divergence = get_kl_divergence tags, actual_tags
    count_comparison = get_count_comparison tags, actual_tags
    stats[doc] = { :kl_divergence => kl_divergence, :count_comparison => count_comparison, :have_shared_tag => count_comparison > 0.0 }
    #binding.pry
  end
  print_summary_stats stats
end

if ARGV.length < 4
  puts "Usage: ruby #{__FILE__} <original_data_dir> <inference_model> <topic_tags> <questions-to-infer-topics dir>"
  exit(1)
end
evaluate_tag_inference(ARGV[0], ARGV[1], "/Applications/mallet-2.0.7/bin/mallet", ARGV[2], ARGV[3])
