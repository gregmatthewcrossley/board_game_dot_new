# This is the base application file that encapsulates all of the app's 
# functions in FunctionsFramework.http calls, allowing them to be run
# on Google Cloud Functions.

FunctionsFramework.on_startup do
  require "functions_framework"
  require_relative './lib/board_game'
  # ENV["GOOGLE_APPLICATION_CREDENTIALS"] = "./google_application_credentials.json" 
end

# Given game parameters (topic, player count, game length), returns 
# JS that appends the landing page with "preview" content for a given topic
FunctionsFramework.http("generate_preview_content") do |request|
  topic = CGI.escape_html(request.params["topic"])
  board_game = BoardGame.new(topic).tap do |b|
    b.game_board
    b.game_box
    b.game_pieces
    b.question_cards
    b.chance_cards
  end
  return board_game.name

  def game_board
    @game_board ||= GameBoard.new
  end

  def game_box
    @game_box ||= GameBox.new(@topic)
  end

  def game_pieces
    @game_pieces ||= GamePieces.new(@analyzed_text).all
  end

  def question_cards
    @question_cards ||= CardSet::Question.new(@analyzed_text).generate
  end

  def chance_cards 
    @chance_cards ||= CardSet::Chance.new(@analyzed_text).generate
  end


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