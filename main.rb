require './downloader'
require 'pp'
require 'pry'

def get_all_questions_and_answers_for_user(user, downloader, data_path)
  user_path = File.join(data_path, user['user_id'].to_s)
  answers_path = File.join(user_path, 'answers')
  question_path = File.join(user_path, 'questions')
  raw_path = File.join(user_path, 'raw')

  FileUtils.mkdir_p answers_path
  FileUtils.mkdir_p question_path
  FileUtils.mkdir_p raw_path
  begin
    questions = downloader.get_questions user
    answers = downloader.get_answers user
  rescue StandardError => e
    puts "error downloading questions or answers?"
    puts "finished on #{u}"
    File.open(File.join(data_path, "users_to_finish.json"), "w") do |f|
      f.write(users[i..-1].to_json)
    end
    exit
  end

  File.open(File.join(raw_path, "questions.json"), "w") do |f|
    f.write questions.to_json
  end

  File.open(File.join(raw_path, "answers.json"), "w") do |f|
    f.write answers.to_json
  end
end

d = Downloader.new

out_path = "./middle_users"

users = d.get_users([1000, { :sort => 'reputation', :order => 'desc', :min => '2000', :max => '10000' }])

users.each_with_index do |user, i|
  if d.requests_used_up?
    puts "requests used up for the day!"
    puts "finished on #{i}"
    File.open("./data/users_to_finish.json", "w") do |f|
      f.write(users[i..-1].to_json)
    end
    exit
  else
    get_all_questions_and_answers_for_user(user, d, out_path)
  end
end


