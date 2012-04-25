require 'sinatra'
require 'json'
require 'rack-cors'
require './infer_tags'

MALLLET_INFERENCE_MODEL = './model.inference'
TOPIC_TAGS = './topic_tags.json'

use Rack::Cors do
  allow do
    origins '*'
    resource '*', :methods => [:get, :post]
  end
end

post '/tags' do
  content_type :json
  binding.pry
  request.body.rewind
  data = JSON.parse request.body.read
  puts "data is #{data}"
  get_tags data['document']
end

def get_tags(document)
  nil
end
