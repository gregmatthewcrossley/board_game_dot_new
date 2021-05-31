# This is the base application file that encapsulates all of the app's 
# functions in FunctionsFramework.http calls, allowing them to be run
# on Google Cloud Functions.

FunctionsFramework.on_startup do
  require "functions_framework"
  require_relative './lib/board_game'
  
  # for error reporting
  use Google::Cloud::ErrorReporting::Middleware

end

# Given game parameters (topic, player count, game length), returns 
# JS that appends the landing page with "preview" content for a given topic
FunctionsFramework.http("generate_preview_content") do |request|
  # sanitize the topic string provided by the user
  topic = CGI.escape_html(request.params["topic"])
  # initialize and generate the board game
  board_game = BoardGame.new(topic).generate
  # save the board game PDF to Google Cloud Storage
  game_file_name = "#{board_game.topic} Board Game Kit.pdf"
  temp_file_path = "./.temp_pdf/#{game_file_name}"
  board_game.pdf.save temp_file_path
  Google::Cloud::Storage.new
    .bucket('board-game-dot-new')
    .create_file(
      temp_file_path,
      ".game_pdfs/#{board_game.topic}/#{game_file_name}", 
      acl: "bucketOwnerFullControl"
    )
  File.delete temp_file_path
  # return JSON with preview content
  return {
    name: board_game.name,
    description: board_game.description
  }.to_json 
end
# http://localhost:8080/?topic=Rob+Ford

# Given game parameters (topic, player count, game length), returns
# the ID of a Stripe Checkout Session for use by Stipe Checkout on the 
# client side
FunctionsFramework.http("create_stripe_checkout_session") do |request|
  Stripe.api_key = "sk_test_4GeIsHLcOWrJJuLKhdecy4B4"
  require 'json'

  stripe_checkout_session = Stripe::Checkout::Session.create({
    payment_method_types: ['card'],
    line_items: [{
      price: 'price_1IvT2wKPc8URRCXAFjGAPHnb', # see https://dashboard.stripe.com/products/prod_JYR2C1kMen7g2X
      quantity: 1
    }],
    mode: 'payment',
    metadata: {
      topic: CGI.escape_html(request.params["topic"]),
      download_url: "***", # write a method to generate an encrypted URL
      expires_on: (Date.today + 14).to_s
    },
    success_url: 'https://boardgame.new/success.html?stripe_checkout_session_id={CHECKOUT_SESSION_ID}"',
    cancel_url:  'https://boardgame.new'
  })
  
  return { id: stripe_checkout_session.id }.to_json
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