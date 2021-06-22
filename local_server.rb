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
  '/functions/topics' => URI.parse("http://localhost:8001/")
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
    uri = FUNCTIONS[request.path]
    response.body = Net::HTTP.get_response(uri).body
  end
end

# shuddown if interupted
trap 'INT' do server.shutdown end

# start the server
server.start