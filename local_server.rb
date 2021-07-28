# Local Server
# Use this to simulate Google Cloud Storage web serving
# and web access to Google Cloud Functions on your development machine

require 'webrick'
require 'pry'
require 'net/http'
require 'uri'

# define a hash mapping relative function paths to the localhost and port 
# of the locally hosted google function 
FUNCTIONS = {
  '/functions/topics'                 => "http://localhost:8001/",
  '/functions/topic_existence_check'  => "http://localhost:8002/",
  '/functions/topic_word_count_check' => "http://localhost:8003/",
  '/functions/topic_image_check'      => "http://localhost:8004/",
  '/functions/topic_analysis'         => "http://localhost:8005/",
  '/functions/preview_component'      => "http://localhost:8006/"
}

# serve all static files from the landing-page folder
root = File.expand_path './landing-page'

# create a new Webbrick server
server = WEBrick::HTTPServer.new(
  :Port => 8000, 
  :DocumentRoot => root
)

# mount a Proc that intercepts any '/function' requests, 
# find the corresponding local URI, retrieves its content
# and returns that content as the response body
server.mount_proc '/functions' do |request, response|
  if FUNCTIONS.keys.include?(request.path)
    # look up the local path and port for this request
    local_uri_string = FUNCTIONS[request.path]
    # add any query strings to the uri string
    local_uri_string = local_uri_string + '?' + request.query_string if request.query_string
    # send request to the local path, return its header and body
    local_response = Net::HTTP.get_response(URI.parse(local_uri_string))
    response.status = local_response.code.to_i
    response.body   = local_response.body
  else
    response.status = 404
  end
end

# shuddown if interupted
trap 'INT' do server.shutdown end

# start the server
server.start