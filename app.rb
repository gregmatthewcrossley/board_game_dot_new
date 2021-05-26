# This is the base application file that encapsulates all of the app's 
# functions in FunctionsFramework.http calls, allowing them to be run
# on Google Cloud Functions.

FunctionsFramework.on_startup do
  require "functions_framework"
  require_relative './lib/board_game'
  ENV["GOOGLE_APPLICATION_CREDENTIALS"] = "./google_application_credentials.json" 
end

# Given game parameters (topic, player count, game length), returns 
# JS that appends the landing page with "preview" content for a given topic
FunctionsFramework.http("generate_preview_content") do |request|
  topic = CGI.escape_html(request.params["topic"])
  board_game = BoardGame.new(topic)
  return board_game.name
end
# http://localhost:8080/?topic=Rob+Ford

# Given game parameters (topic, player count, game length), returns
# the ID of a Stripe Checkout Session for use by Stipe Checkout on the 
# client side
FunctionsFramework.http("create_stripe_checkout_session") do |request|
  "Create Stripe Checkout Session"
end

# Given game parameters (topic, player count, game length), and an
# expiration date, returns a URL to download the full game PDF, 
# with the parameters and expiration date encrypted as a query string.
FunctionsFramework.http("generate_game_pdf_download_url") do |request|
  "Generate Game PDF Download"
end

# Receives download requests, decrypts the query string, and if the 
# exipration date isn't past, serves the game PDF (either freshly
# generated or served from the database, if it exists there).
FunctionsFramework.http("retrieve_game_pdf") do |request|
  "Retrieve Game PDF"
end