require 'json'
require 'lunker'

# The plan:
# we can only download a certain number of questions per day. 10,000 I think.
# So we loop through all answers until we find one without a tag array and start there.

# Do them in batches of 100, so we maximize the requests we can do

# Takes a path to a directory full of user_id directories, each
# with a raw directory containing json we need to parse and
# manipulate
def get_tags_for_answers(dir)
  Dir[File.join(dir, '*')].each do |user_dir|
    add_tags_to_answers(File.join(user_dir, 'raw', 'answers.json'))
  end
end

def need_tags?(answers)
  answers[-1]['tags'].nil?
end

def get_question_ids(answers)
  question_ids = []
  answers.each do |answer|
    # skip over already-completed files
    next if answer['tags']
    question_ids << answer['question_id']
  end
  question_ids
end

def get_questions(question_ids)
  Lunker::StackOverflow.new.questions question_ids
end

def update_answers_with_tags(answers, questions)
  questions.each do |question|
    #TODO: this will only return copies?
    answers_for_question = answers.select { |a| a['question_id'] == question['question_id'] }
    binding.pry if answers_for_question.length == 0
    answers_for_question.each do |answer|
      answer['tags'] = question['tags']
    end
  end
  answers
end

def write_tagged_answers(path, answers)
  open("#{path}.tagged", "w") do |f|
    f.write(answers.to_json)
  end
end

def add_tags_to_answers(answer_file_path)
  p answer_file_path
  updated_answers = nil
  open(answer_file_path, 'rb') do |f|
    answers = JSON.parse(f.read)
    # bail out if we don't need to process this file
    if !need_tags? answers
      puts "don't need tags for #{answers}"
      return nil
    end
    question_ids = get_question_ids(answers)
    questions = get_questions(question_ids)
    updated_answers = update_answers_with_tags(answers, questions)
  end

  write_tagged_answers(answer_file_path, updated_answers)
end


if __FILE__ == $0
  if ARGV.length < 1
    puts "Usage: ruby #{__FILE__} <directory_containing_user_id_dirs>"
    exit(1)
  end
  get_tags_for_answers(ARGV[0])
end

