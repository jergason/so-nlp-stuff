# Utils used by a few mallet processing scripts
module TagInferencer
  module MalletUtils
    def load_and_parse_question_or_answer_file(filename, original_data_dir)
      file_to_load = get_filename_to_load_from_mallet_document_name(filename)
      loaded_file = nil
      open(File.join(original_data_dir, file_to_load), 'r') do |f|
        loaded_file = JSON.parse(f.read)
      end

      loaded_file
    end

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
  end
end
