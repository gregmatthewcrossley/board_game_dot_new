# This is the base application file that encapsulates all of the app's 
# functions in FunctionsFramework.http calls, allowing them to be run
# on Google Cloud Functions.

FunctionsFramework.on_startup do
  require "functions_framework"
  require_relative './lib/board_game'
  require_relative './game_purchase/*.rb'
end

# Given game parameters (topic, player count, game length), returns 
# JS that appends the landing page with "preview" content for a given topic
FunctionsFramework.http("generate_preview_content") do |request|
  begin # for error reporting
    # sanitize the topic string provided by the user
    topic = CGI.escape_html(request.params["topic"])
    # initialize and generate the board game
    board_game = BoardGame.new(topic).generate
    # save the board game PDF to Google Cloud Storage
  
    game_file_name = "#{board_game.topic} Board Game Kit.pdf"
    temp_file_path = "/tmp/#{game_file_name}" # https://cloud.google.com/functions/docs/concepts/exec#file_system%20Max%20memory%20right%20now%20is%202048mb%20so%20you’ll%20have%20to%20keep%20it%20under%20that%20assuming%20you’ve%20provisioned%20your%20function%20with%20that%20much%20memory.%20%20Hope%20it%20helps%20someone!%20%20Search%20for:%20%20Recent%20Posts%20Por%20Hamlet%20For%20Hamlet.%20Writing%20to%20temporary%20storage%20in%20a%20Google%20Cloud%20Function%20using%20Node%20JS%20Zorgon%20valley%20boxfaced%20fish%20–%20Full%20bio%20From%20Excel%20to%20Jupyter%20Notebooks%20(part%201:%20installation)%20Categories%20Excel%20Friends%20Fun%20Google%20docs%20How%20to%20Live%20SEO%20tests%20Opinion%20Programming%20Scraping%20Technical%20SEO%20Tools%20Uncategorized
    board_game.pdf.render_file temp_file_path
    saved_pdf = Google::Cloud::Storage.new
      .bucket('board-game-dot-new')
      .create_file(
        temp_file_path,
        ".game_pdfs/#{board_game.topic}/#{game_file_name}", 
        acl: "publicRead",
      )
    File.delete temp_file_path
    # return JSON with preview content
    return {
      name: board_game.name,
      description: board_game.description
    }.to_json 
  rescue StandardError => e
    Google::Cloud::ErrorReporting.report e
  end
end
# http://localhost:8080/?topic=Rob+Ford

# Given a topic, returns a hash with the ID of a Stripe Checkout Session 
# for use by Stipe Checkout on the client side
FunctionsFramework.http("create_stripe_checkout_session") do |request|
  begin
    topic = CGI.escape_html(request.params["topic"])
    email = CGI.escape_html(request.params["email"])
    session = GamePurchase.create_stripe_checkout_session(topic, email)
    return { id: session.id }.to_json # sent back to the Stripe JS client on the customer's browser
  rescue StandardError => e
    Google::Cloud::ErrorReporting.report e
  end
end

# Given a Stripe::Checkout session ID, redirects the client to an HTML with the game PDF download link.
FunctionsFramework.http("show_checkout_complete_page") do |request|
  begin
    # parse the session ID from the query string
    session_id = CGI.escape_html(request.params["stripe_checkout_session_id"])
    # retrieve the session from Stripe
    begin
      session = StripeSession.retrieve(session_id)
    rescue Stripe::InvalidRequestError
      # redirect to 404 static HTML
      return ::Rack::Response.redirect("/404.html")
    end

    # if the payment isn't complete, redirect to 'expired' static HTML
    return ::Rack::Response.redirect("/not_paid.html?topic=#{topic}") if session.payment_status != "paid"

    # initialize the key variables
    topic, download_key, download_url, expires_after = nil
    # get the key variables from the metadata
    session.metadata.to_h.tap do |m|
      raise ArgumentError, 'metadata has no topic'         unless topic         = m[:topic]
      raise ArgumentError, 'metadata has no download_key'  unless download_key  = m[:download_key]
      raise ArgumentError, 'metadata has no download_url'  unless download_url  = m[:download_url]
      raise ArgumentError, 'metadata has no expires_after' unless expires_after = Date.parse(m[:expires_after])
    end

    # Redirection logic
    if (Date.today - expires_after > 0)
      # if expired, redirect to 'expired' static HTML
      return ::Rack::Response.redirect("/link_expired.html?topic=#{topic}")
    else
      # redirect to 'download page' static HTML 
      return ::Rack::Response.redirect("/paid.html?download_key=#{download_key}")
    end
  rescue StandardError => e
    Google::Cloud::ErrorReporting.report e
  end
end

# Receives download requests, decrypts the query string, and if the 
# exipration date isn't past, serves the game PDF (either freshly
# generated or served from the database, if it exists there).
FunctionsFramework.http("retrieve_game_pdf") do |request|
  begin
    # parse the session ID from the query string
    key = CGI.escape_html(request.params["key"])
    # initialize the topic and email variables
    topic, email = nil
    # decrypt the key and get the topic and email values
    DownloadKey.decrypt_to_hash(key).tap do |key_data|
      topic = key_data[:topic]
      email = key_data[:email]
    end
    raise ArgumentError, ':topic was not found in the decrypted key' unless topic
    raise ArgumentError, ':email was not found in the decrypted key' unless email
    begin
      # find the Stripe customer
      customers = Stripe::Customer.list({email: email}).data
      raise ArgumentError, "no customers found with email address '#{email}'" unless customers.any?
      # find all payment intents for this customer
      payment_intents = Stripe::PaymentIntent.list({customer: customers.last}).data
      raise ArgumentError, "no payment_intents found for customer '#{email}'" unless payment_intents.any?
      # find all payments for this customer
      succeeded_payment_intents = payment_intents.select {|p| p.status == "succeeded"}
      raise ArgumentError, "no 'succeeded' payment_intents found for customer '#{email}'" unless succeeded_payment_intents.any?
      # find all checkout sessions for this payment intent
      sessions = Stripe::Checkout::Session.list({payment_intent: succeeded_payment_intents.last.id}).data
      raise ArgumentError, "no checkout sessions found for payment_intent '#{succeeded_payment_intents.last.id}'" unless sessions.any?
      raise ArgumentError, "no metadata found for checkout sessions '#{sessions.last.id}'" if sessions.last.metadata.nil?
      # return a 404 header if this session wasn't paid
      return ::Rack::Response.new(nil, 404) if sessions.last.payment_status != "paid"
    rescue Stripe::InvalidRequestError
      # redirect to 404 static HTML
      return ::Rack::Response.redirect("/404.html")
    end
    # get the topic and expiry date from the metadata
    topic, expires_after = nil
    sessions.last.metadata.to_h.tap do |m|
      topic = m[:topic]
      expires_after = Date.parse(m[:expires_after])
    end  
    if (Date.today - expires_after > 0)
      # if expired, redirect to 'expired' static HTML
      return ::Rack::Response.redirect("/link_expired.html?topic=#{topic}")
    else
      # find the file in Google Cloud Storage
      files_matching_topic = Google::Cloud::Storage.new
        .bucket('board-game-dot-new')
        .files(prefix: ".game_pdfs/#{topic}/")
      return ::Rack::Response.redirect("/404.html") unless files_matching_topic.any?
      # download the file to the Google Functions Ruby runtime as an in-memory StringIO object
      file = files_matching_topic.last.download.tap(&:rewind)
      raise ArgumentError, "file for topic '#{topic}' could not be downloaded" unless file.is_a?(StringIO)
      # send the file to the client
      return Rack::Response.new.tap do |r|
        r.headers.merge!( "Content-Type" => 'application/pdf' )
        r.write file
      end
    end
  rescue StandardError => e
    Google::Cloud::ErrorReporting.report e
  end
end

