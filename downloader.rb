require 'lunker'

class Downloader
  attr_accessor :low_cutoff

  def initialize(api_key=nil, filter="!0YMBtdk9)8cW.V-o1xluM)Sy5")
    Lunker.configure
    Lunker.configure do |conf|
      # include bodies on questions, answers, comments.
      conf.api_key = api_key unless api_key.nil?
      conf.filter = filter
    end
    @user_downloader = Lunker::StackOverflow.new
    # daily limit
    @low_cutoff = 500
  end

  def requests_used_up?
    Lunker.requests_remaining < @low_cutoff
  end

  def get_users(limit, params)
    @user_downloader.users limit, params
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

  def get_tags(user_id)
    u = Lunker::User.new user_id.to_i

    u.tags
  end
end
