require 'lunker'
require 'pry'

class Downloader
  attr_accessor :low_cutoff
  def initialize
    Lunker.configure do |conf|
      # include bodies on questions, answers, comments.
      conf.filter = "!0YMBtdk9)8cW.V-o1xluM)Sy5"
    end
    @user_downloader = Lunker::StackOverflow.new
    # daily limit
    @low_cutoff = 500
  end

  def requests_used_up?
    Lunker.requests_remaining < @low_cutoff
  end


  def get_users(args)
    res = @user_downloader.users(*args)
  end

  def get_questions(user)
    raise "HURP DURP" if user['user_id'].nil?

    u = Lunker::User.new user['user_id'].to_i

    u.questions
  end

  def get_answers(user)
    raise "HURP DURP" if user['user_id'].nil?

    u = Lunker::User.new user['user_id'].to_i

    u.answers
  end
end
