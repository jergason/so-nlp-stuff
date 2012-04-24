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

    # Takes a path to a document, and returns the top inferred tags
    # for that document.
    #
    # returns an array of inferred tags, roughly in order of relevance
    def infer_tags_for_document(document)
      mallet_output = infer_topics(document, @mallet_path, @inferencer_path)
      topic_distribution = mallet_output.split("\n")[1].strip.split(" ")
      #binding.pry
      # cache topic tags so don't need to reload
      @topic_tags = load_topic_tags(@topic_tags_path) if @topic_tags.nil?
      topic_proportions = ::TagInference::TopicTagAnalyzer.get_topic_proportions(topic_distribution)
      top_topics = get_top_topics(topic_proportions)
      inferred_tags = get_tags_for_topics(top_topics, @topic_tags)

      inferred_tags
    end


    private
    def infer_topics(document, mallet_path, inferencer_path)
      if cached? document
        return get_from_cache document
      end

      `rm -rf tmp_infer_topics`
      `mkdir -p tmp_infer_topics`
      doc = nil
      open(document, 'r') { |f| doc = f.read }
      open('tmp_infer_topics/tmp.txt', 'wb') {|f| f.write(doc) }

      `#{mallet_path} import-dir --input tmp_infer_topics --output tmp_infer_topics/tmp.mallet --keep-sequence --remove-stopwords`
      `#{mallet_path} infer-topics --inferencer #{inferencer_path} --input tmp_infer_topics/tmp.mallet --output-doc-topics tmp_infer_topics/tmp_output_doc_topics.txt`
      topic_distro = nil
      open('tmp_infer_topics/tmp_output_doc_topics.txt', 'r') do |f|
        topic_distro = f.read
      end
      write_to_cache topic_distro, document

      topic_distro
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

      suggested_tags[0..4]
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
