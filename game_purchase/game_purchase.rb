class GamePurchase

  require 'json'

  DAYS_AVAILABLE = 14 # number of days the download link will work

  def self.create_stripe_checkout_session(topic, email)
    raise ArgumentError, "must pass a String for topic" unless topic.is_a?(String)
    raise ArgumentError, "must pass a String for email" unless email.is_a?(String)
    Stripe.api_key = ENV['STRIPE_API_KEY']
    download_key = DownloadKey.new(topic, email).encrypted_download_key
    download_url = "https://boardgame.new/download?key=#{download_key}"
    session = Stripe::Checkout::Session.create({
      payment_method_types: ['card'],
      line_items: [{
        price: 'price_1IvT2wKPc8URRCXAFjGAPHnb', # see https://dashboard.stripe.com/products/prod_JYR2C1kMen7g2X
        quantity: 1,
        description: "DIY Board Game Kit: '#{topic}' \n Download Link: #{download_link} \nThis link will work after payment for #{DAYS_AVAILABLE} days."
      }],
      mode: 'payment',
      metadata: {
        topic: topic,
        download_key: download_key,
        download_url: download_url,
        expires_after: (Date.today + DAYS_AVAILABLE).to_s
      },
      success_url: "https://boardgame.new/checkout_complete?stripe_checkout_session_id={CHECKOUT_SESSION_ID}",
      cancel_url:  "https://boardgame.new?topic=#{CGI.escape_html(topic)}"
    })
  end

  def self.retrieve_stripe_checkout_session(session_id)
    Stripe.api_key = ENV['STRIPE_API_KEY']
    Stripe::Checkout::Session.retrieve(session_id)
  end

end