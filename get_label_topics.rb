require 'json'
module TagInference
  class TopicTagAnalyzer
    attr_reader :doc_topic_distribution, :original_data_dir
    def initialize(doc_topic_distribution, original_data_dir)
      @doc_topic_distribution = doc_topic_distribution
      @original_data_dir = original_data_dir
    end

    # Write the per-topic tag recommendations to a JSON array stored at write_path
    def write_out_top_tags_for_topics(write_path)
      puts "Getting distribution"
      topic_tag_distribution = calculate_topic_tag_distribution(@doc_topic_distribution, @original_data_dir)

      puts "Finding top topics"

      # Do this greedily?
      top_tags = []
      chosen_tags = []
      topic_tag_distribution[0..-1].each_with_index do |tag_distribution, i|
        #remove_chosen_tags(tag_distribution, chosen_tags)
        top_tag = tag_distribution.sort_by { |tag, proportion| proportion }.reverse[0][0]
         #chosen_tags << top_tag
        top_tags[i] = top_tag
      end

      open(write_path, 'wb') do |f|
        f.write(top_tags.to_json)
      end
    end

    # Parse a line of mallet topic proportions into and array where the
    # indicies are the topic indicies and the values are the poportions of that topic
    def self.get_topic_proportions(fields)
      topics = []
      # skip first line, because it is the filename
      # skip last item because it is a newline, and messes things up
      fields[2...-1].each_slice(2) do |topic_proportion|
        topics[topic_proportion[0].to_i] = topic_proportion[1].to_f
      end

      topics
    end

    private
    def parse_mallet_filename(filename)
      parts = filename.split('/')[-1].split('-')
      parts[2] = parts[2].split(".")[0]
      if parts[1] =~ /question/
        is_question = true
      else
        is_question = false
      end
      { :user_id => parts[0], :is_question => is_question, :q_or_a_id => parts[2].to_i }
    end

    def get_filename_to_load_from_mallet_document_name(filename)
      parsed_name = parse_mallet_filename(filename)
      if parsed_name[:is_question]
        data_filename = 'questions.json'
      else
        data_filename = 'answers.json.tagged'
      end
      "#{parsed_name[:user_id]}/raw/#{data_filename}"
    end

    # TODO: use MalletUtils
    def load_and_parse_question_or_answer_file(filename, original_data_dir)
      file_to_load = get_filename_to_load_from_mallet_document_name(filename)
      loaded_file = nil
      open(File.join(original_data_dir, file_to_load), 'r') do |f|
        loaded_file = JSON.parse(f.read)
      end

      loaded_file
    end

    # TODO: use MalletUtils
    def get_tags_for_document(document_name, loaded_document)
      parsed_name = parse_mallet_filename(document_name)
      tags = nil
      if parsed_name[:is_question]
        tags = loaded_document.select { |doc| doc['question_id'] == parsed_name[:q_or_a_id] }[0]['tags']
      else
        tags = loaded_document.select { |doc| doc['answer_id'] == parsed_name[:q_or_a_id] }[0]['tags']
      end

      tags
    end


    # Calculate the distribution of tags for each topic.
    # mallet_doc_topic_file - path of a mallet doc topic file to import
    # num_topics - number of topics in the topic
    # returns an array of hashes of tags. Each index in the array is a topic id,
    # and each value is a hash containing the distribution of tags over that
    # topic. Higher numbers are more probable.
    def calculate_topic_tag_distribution(mallet_doc_topic_file, original_data_dir, num_topics=100)
      if File.exists?("#{mallet_doc_topic_file}.distribution")
        topic_tag_distribution = nil
        open("#{mallet_doc_topic_file}.distribution", 'r') do |f|
          topic_tag_distribution = Marshal.load(f.read)
        end
        return topic_tag_distribution
      end

      count = 0
      topic_tag_distribution = Array.new(num_topics) { Hash.new }
      loaded_document_name = nil
      loaded_document = nil
      open(mallet_doc_topic_file, 'r') do |f|
        f.each do |doc|
          count += 1
          puts "On #{count}" if count % 10000 == 0
          # skip the first line
          next if doc =~ /#doc name topic proportion/
          # get the tags for the document
          fields = doc.split("\t")
          document_name = fields[1]
          q_or_a_filename = get_filename_to_load_from_mallet_document_name(document_name)
          topic_proportions_for_current_doc = TopicTagAnalyzer.get_topic_proportions(fields)

          if loaded_document_name != q_or_a_filename
            loaded_document_name = q_or_a_filename
            loaded_document= load_and_parse_question_or_answer_file(document_name, original_data_dir)
          end

          tags_for_document = get_tags_for_document(document_name, loaded_document)
          #binding.pry
          next if tags_for_document.nil?


          # for each topic in the document
          #   for each tag in the document
          #     increase the tag proportion by the amount of that topic
          topic_tag_distribution.each_with_index do |topic_tags, i|
            next if topic_proportions_for_current_doc[i].nil?
            tags_for_document.each do |tag|
              topic_tags[tag] = 0.0 if topic_tags[tag].nil?
              topic_tags[tag] += topic_proportions_for_current_doc[i]
            end
          end
        end
      end
      open("#{mallet_doc_topic_file}.distribution", 'w') do |f|
        #binding.pry
        f.write(Marshal.dump(topic_tag_distribution))
      end

      topic_tag_distribution
    end

    def remove_chosen_tags(tag_distro, chosen_tags)
      chosen_tags.each do |chosen_tag|
        tag_distro.delete chosen_tag
      end
    end

  end
end



if __FILE__ == $0

  if ARGV.length < 3
    puts "Usage: #{__FILE__} <mallet-doc-topic file> <original-data-dir> <output path for top tags>"
    exit(1)
  end

  foo = TagInference::TopicTagAnalyzer.new(ARGV[0], ARGV[1])
  foo.write_out_top_tags_for_topics(ARGV[2])
end
