class GamePurchase

  require 'json'

  PATH_TO_SECRETS_YAML = "/Users/gmc/Code/board_game_dot_new/.secrets.yaml"

  PRICE_IN_CENTS = 500
  CURRENCY = 'CAD'
  DAYS_AVAILABLE = 14 # number of days the download link will work

  def self.create_stripe_checkout_session(topic, email)
    raise ArgumentError, "must pass a String for topic" unless topic.is_a?(String)
    raise ArgumentError, "must pass a String for email" unless email.is_a?(String)
    ensure_stripe_api_keys_are_saved_to_environment
    Stripe.api_key = ENV['STRIPE_API_KEY']
    download_key = DownloadKey.new(topic, email).encrypted_download_key
    download_url = "https://boardgame.new/functions/download?download_key=#{download_key}"
    description = "Download link: #{download_url} (will only work after payment, for #{DAYS_AVAILABLE} days)"
    session = Stripe::Checkout::Session.create({
      mode: "payment",
      payment_method_types: ['card'],
      customer_email: email,
      line_items: [{
        price_data: {
          product_data: {
            name: "'#{topic}' Board Game Making Kit", #  'Rob Ford' Board Game Making Kit
            metadata: {
              topic: topic
            }
          },
          unit_amount: PRICE_IN_CENTS,
          currency: CURRENCY,
        },
        description: description,
        quantity: 1
      }],
      metadata: {
        topic: topic,
        download_key: download_key,
        download_url: download_url,
        expires_after: (Date.today + DAYS_AVAILABLE).to_s
      },
      success_url: "https://boardgame.new/functions/checkout_complete?stripe_checkout_session_id={CHECKOUT_SESSION_ID}",
      cancel_url:  "https://boardgame.new?topic=#{CGI.escape_html(topic)}"
    })
  end

  def self.retrieve_stripe_checkout_session(session_id)
    raise ArgumentError, "must pass a String for session_id" unless session_id.is_a?(String)
    ensure_stripe_api_keys_are_saved_to_environment
    Stripe.api_key = ENV['STRIPE_API_KEY']
    Stripe::Checkout::Session.retrieve(session_id)
  end

  def self.paid_stripe_session_for(topic, email)
    raise ArgumentError, "must pass a String for topic" unless topic.is_a?(String)
    raise ArgumentError, "must pass a String for email" unless email.is_a?(String)
    begin
      ensure_stripe_api_keys_are_saved_to_environment
      Stripe.api_key = ENV['STRIPE_API_KEY']
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
      # return false if this session wasn't paid      
      return sessions.last #.payment_status == "paid" || true
    rescue Stripe::InvalidRequestError
      return nil
    end
  end

  def self.save_stripe_api_keys_to_environment
    YAML.load(File.read(PATH_TO_SECRETS_YAML)).tap do |keys|
      ENV['STRIPE_API_KEY'] = keys['STRIPE_API_KEY']
    end
  end


  private


  def self.ensure_stripe_api_keys_are_saved_to_environment
    GamePurchase.save_stripe_api_keys_to_environment if ENV['STRIPE_API_KEY'].nil?
  end

end