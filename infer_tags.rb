require 'json'
require 'pry'
$LOAD_PATH.unshift '.'
require 'get_label_topics'

module TagInference
  class Inferencer
    attr_reader :mallet_path, :inferencer_path, :topic_tags_path, :topic_tags
    def initialize(mallet_path, inferencer_path, topic_tags_path)
      @mallet_path = mallet_path
      @inferencer_path = inferencer_path
      @topic_tags_path = topic_tags_path
      @topic_tags = nil
    end

    # Takes a path to a document or directory of documents, and returns the top inferred tags
    # for that document or all for that directory
    #
    # returns an array of inferred tags, roughly in order of relevance
    def infer_tags_for_document(document)
      mallet_output = infer_topics(document, @mallet_path, @inferencer_path)

      if File.directory? document
        # first line is just the key, so ignore it
        topic_distributions = mallet_output.split("\n")
        topic_distributions.shift
        inferred_tags_per_document = {}
        topic_distributions.each do |topic|
          doc_name = topic.strip.split(" ")[1]
          inferred_tags_per_document[doc_name] = tags_for_topic_distro topic.strip.split(" ")
        end
        inferred_tags_per_document
      else
        topic_distribution = mallet_output.split("\n")[1].strip.split(" ")
        inferred_tags = tags_for_topic_distro topic_distribution
      end
    end

    private
    def tags_for_topic_distro(topic_distribution)
      # cache tags so we can reuse if needed
      @topic_tags = load_topic_tags(@topic_tags_path) if @topic_tags.nil?
      topic_distribution << 'tmp' unless topic_distribution.length.odd?
      topic_proportions = ::TagInference::TopicTagAnalyzer.get_topic_proportions(topic_distribution)
      top_topics = get_top_topics(topic_proportions)
      inferred_tags = get_tags_for_topics(top_topics, @topic_tags)

      inferred_tags
    end

    def infer_topics(document, mallet_path, inferencer_path)
      if cached? document
        return get_from_cache document
      end

      if File.directory? document
        return infer_topics_on_dir document, mallet_path, inferencer_path
      end

      tmp_dir = 'tmp_infer_topics'
      tmp_input_file = "#{tmp_dir}/tmp.txt"
      tmp_mallet_input = "#{tmp_dir}/tmp.mallet"
      tmp_doc_topics = "#{tmp_dir}/tmp_output_doc_topics.txt"

      `rm -rf #{tmp_dir}`
      `mkdir -p #{tmp_dir}`
      doc = nil
      open(document, 'r') { |f| doc = f.read }
      open(tmp_input_file, 'wb') {|f| f.write(doc) }

      run_mallet_import(mallet_path, tmp_dir, tmp_mallet_input)
      run_mallet_inference(mallet_path, inferencer_path, tmp_mallet_input, tmp_doc_topics)
      topic_distro = nil
      open(tmp_doc_topics, 'r') do |f|
        topic_distro = f.read
      end
      write_to_cache topic_distro, document

      topic_distro
    end

    def infer_topics_on_dir(document, mallet_path, inference_path)
      tmp_mallet_input = "tmp_mallet_input.mallet"
      tmp_doc_topics = "tmp_doc_topics.txt"
      run_mallet_import mallet_path, document, tmp_mallet_input
      run_mallet_inference mallet_path, inference_path, tmp_mallet_input, tmp_doc_topics
      topic_distro = nil
      open(tmp_doc_topics, 'r') do |f|
        topic_distro = f.read
      end
      write_to_cache topic_distro, document

      topic_distro
    end

    def run_mallet_import(mallet_path, input, output)
      `#{mallet_path} import-dir --input #{input} --output #{output} --keep-sequence --remove-stopwords`
    end

    def run_mallet_inference(mallet_path, inferencer, input, output)
      `#{mallet_path} infer-topics --inferencer #{inferencer} --input #{input} --output-doc-topics #{output}`
    end

    def cached?(document_path)
      File.exists? "#{document_path}.mallet_output"
    end

    def get_from_cache(document)
      loaded_doc = nil
      open "#{document}.mallet_output", "r" do |f|
        loaded_doc = f.read
      end

      loaded_doc
    end

    def write_to_cache(doc, path)
      open "#{path}.mallet_output", "w" do |f|
        f.write doc
      end
    end

    def load_topic_tags(topic_tags_location)
      topics = nil
      open(topic_tags_location, 'r') do |f|
        topics = JSON.parse f.read
      end
      topics
    end

    # Take and array of [topic_id] = proportions
    # and return a sorted array of [tid, proportion] pairs,
    # sorted by proportion
    def get_top_topics(topic_proportions)
      sorted_topics = {}
      topic_proportions.each_with_index do |proportion, i|
        sorted_topics[i] = proportion
      end

      sorted_topics.sort_by { |topic_id, proportion| proportion }.reverse
    end

    # Return an array of tags, along with a score, for the topics in document_topics
    def get_tags_for_topics(document_topics, tags_for_topics, limit=5)
      suggested_tags = []
      document_topics.each do |topic|
        suggested_tags << tags_for_topics[topic[0]]
      end

      suggested_tags[0..20]
    end
  end
end


if __FILE__ == $0
  if ARGV.length < 3
    puts "Useage: ruby infer_tags.rb <path to document> <path to mallet inference model> <path to tags for topics file>"
    exit(1)
  end

  mallet_path = "/Applications/mallet-2.0.7/bin/mallet"
  foo = TagInference::Inferencer.new(mallet_path, ARGV[1], ARGV[2])
  puts foo.infer_tags_for_document(ARGV[0])
end
