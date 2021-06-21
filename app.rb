# This is the base application file that encapsulates all of the app's 
# functions in FunctionsFramework.http calls, allowing them to be run
# on Google Cloud Functions.

# Shared Startup Functions
FunctionsFramework.on_startup do
  require "functions_framework"
  require_relative './lib/board_game'
  require_all './game_purchase/'
end

# Get a random topic name
# Local testing: 
#   export GOOGLE_APPLICATION_CREDENTIALS="/Users/gmc/Code/board_game_dot_new/google_application_credentials.json"
#   bundle exec functions-framework-ruby --port 8079 --target retrieve_random_topic
#   http://localhost:8079/
FunctionsFramework.http("retrieve_random_topic") do |request|
  begin # for error reporting    
    # return JSON with topic string
    return {
      topic: ExternalTextSource::WikipediaApi::FEATURED_ARTICLE_TITLES.sample
    }.to_json 
  rescue StandardError => e
    Google::Cloud::ErrorReporting.report e
  end
end

# Given game parameters (topic, player count, game length), returns 
# JS that appends the landing page with "preview" content for a given topic.
# Local testing: 
#   export GOOGLE_APPLICATION_CREDENTIALS="/Users/gmc/Code/board_game_dot_new/google_application_credentials.json"
#   bundle exec functions-framework-ruby --port 8080 --target generate_preview_content
#   http://localhost:8080/?topic=Rob+Ford
FunctionsFramework.http("generate_preview_content") do |request|
  begin # for error reporting
    # sanitize the topic string provided by the user
    topic = CGI.escape_html(request.params["topic"])
    # initialize and generate the board game
    BoardGame.log_elapsed_time_for("BoardGame initialization and generation") do
      board_game = BoardGame.new(topic).generate
    end

    # save the board game PDF to Google Cloud Storage
    BoardGame.log_elapsed_time_for("BoardGame initialization and generation") do
      game_file_name = "#{board_game.topic} Board Game Kit.pdf"
      temp_file_path = "/tmp/#{game_file_name}" # https://cloud.google.com/functions/docs/concepts/exec#file_system%20Max%20memory%20right%20now%20is%202048mb%20so%20you’ll%20have%20to%20keep%20it%20under%20that%20assuming%20you’ve%20provisioned%20your%20function%20with%20that%20much%20memory.%20%20Hope%20it%20helps%20someone!%20%20Search%20for:%20%20Recent%20Posts%20Por%20Hamlet%20For%20Hamlet.%20Writing%20to%20temporary%20storage%20in%20a%20Google%20Cloud%20Function%20using%20Node%20JS%20Zorgon%20valley%20boxfaced%20fish%20–%20Full%20bio%20From%20Excel%20to%20Jupyter%20Notebooks%20(part%201:%20installation)%20Categories%20Excel%20Friends%20Fun%20Google%20docs%20How%20to%20Live%20SEO%20tests%20Opinion%20Programming%20Scraping%20Technical%20SEO%20Tools%20Uncategorized
      board_game.pdf.render_file temp_file_path
      saved_pdf = Google::Cloud::Storage.new
        .bucket('board-game-dot-new')
        .create_file(
          temp_file_path,
          ".game_pdfs/#{board_game.topic}/#{game_file_name}", 
          acl: "publicRead"
        )
      File.delete temp_file_path
    end
    
    # return JSON with preview content
    return {
      name: board_game.name,
      description: board_game.description
    }.to_json 
  rescue StandardError => e
    Google::Cloud::ErrorReporting.report e
  end
end

# Given a topic, returns a hash with the ID of a Stripe Checkout Session 
# for use by Stipe Checkout on the client side.
# Local testing: 
#   export GOOGLE_APPLICATION_CREDENTIALS="/Users/gmc/Code/board_game_dot_new/google_application_credentials.json"
#   bundle exec functions-framework-ruby --port 8081 --target create_stripe_checkout_session
#   http://localhost:8081/?topic=Rob+Ford&email=mr%40big.com
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
# Local testing:
#   export GOOGLE_APPLICATION_CREDENTIALS="/Users/gmc/Code/board_game_dot_new/google_application_credentials.json"
#   bundle exec functions-framework-ruby --port 8082 --target show_checkout_complete_page
#   http://localhost:8082/?stripe_checkout_session_id=cs_test_a192wx07TD2crSVfDRiOK7bKt8dgy4OgDLtLJTuSxWqw5ypMMbQPT9yZSB
FunctionsFramework.http("show_checkout_complete_page") do |request|
  begin
    # parse the session ID from the query string
    if request.nil? || request.params["stripe_checkout_session_id"].empty?
      raise ArgumentError, "required parameter 'stripe_checkout_session_id' is nil"
    end
    session_id = CGI.escape_html(request.params["stripe_checkout_session_id"])
    # retrieve the session from Stripe
    begin
      session = GamePurchase.retrieve_stripe_checkout_session(session_id)
    rescue Stripe::InvalidRequestError => e
      # redirect to 404 static HTML
      Google::Cloud::ErrorReporting.report e
      return [ 404, {'Location' => "/404.html"}, [] ] 
    end

    # if the payment isn't complete, redirect to 'expired' static HTML
    unless session.payment_status == "paid"
      return [ 302, {'Location' => "/not_paid.html?topic=#{topic}"}, [] ]
    end

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
      return [ 302, {'Location' => "/link_expired.html?topic=#{topic}"}, [] ]
    else
      # redirect to 'success / download page' static HTML 
      return [ 302, {'Location' => "/success.html?topic=#{topic}&download_key=#{download_key}"}, [] ]
    end
  rescue StandardError => e
    Google::Cloud::ErrorReporting.report e
    return [ 404, {'Location' => "/404.html"}, [] ] 
  end
end

# Receives download requests, decrypts the query string, and if the 
# exipration date isn't past, serves the game PDF (either freshly
# generated or served from the database, if it exists there).
# Local testing: 
#   export GOOGLE_APPLICATION_CREDENTIALS="/Users/gmc/Code/board_game_dot_new/google_application_credentials.json"
#   bundle exec functions-framework-ruby --port 8083 --target retrieve_game_pdf
#   http://localhost:8083/?download_key=pngqUvuPuswBW88upmMHUIUNvpY8oA8sO7lYQLsi4XkzHFuZGVuyENByoI8qM2bU
FunctionsFramework.http("retrieve_game_pdf") do |request|
  begin
    # parse the session ID from the query string
    download_key = CGI.escape_html(request.params["download_key"])
    # initialize the topic and email variables
    topic, email = nil
    # decrypt the download_key and get the topic and email values
    DownloadKey.decrypt_to_hash(download_key).tap do |key_data|
      topic = key_data[:topic]
      email = key_data[:email]
    end
    raise ArgumentError, ':topic was not found in the decrypted download_key' unless topic
    raise ArgumentError, ':email was not found in the decrypted download_key' unless email

    # verfify that a customer with this email address has paid for this topic
    unless session = GamePurchase.paid_stripe_session_for(topic, email)
      return [ 404, {'Location' => "/404.html"}, [] ] 
    end
    # get the topic and expiry date from the metadata
    topic, expires_after = nil
    session.metadata.to_h.tap do |m|
      topic = m[:topic]
      expires_after = Date.parse(m[:expires_after])
    end  

    if (Date.today - expires_after > 0)
      # if expired, redirect to 'expired' static HTML
      return [ 302, {'Location' => "/link_expired.html?topic=#{topic}"}, [] ] 
    else
      # find the file in Google Cloud Storage
      files_matching_topic = Google::Cloud::Storage.new
        .bucket('board-game-dot-new')
        .files(prefix: ".game_pdfs/#{topic}/")
      unless files_matching_topic.any?
        return [ 404, {'Location' => "/404.html"}, [] ] 
      end
      # download the file to the Google Functions Ruby runtime as an in-memory StringIO object
      file = files_matching_topic.last
      file_content = file.download.tap(&:rewind)
      raise ArgumentError, "file_content for topic '#{topic}' could not be downloaded" unless file_content.is_a?(StringIO)
      # send the file to the client
      return ::Rack::Response.new.tap do |r|
        r.headers["Content-Type"] = "application/pdf"
        r.headers["Content-Disposition"] = "attachment; filename=\"#{file.name.split('/').last}\""
        r.write(file_content.string)
      end
    end
  rescue StandardError => e
    Google::Cloud::ErrorReporting.report e
  end
end

