require 'date'
require 'base64'
require 'openssl' # for more info, see http://ruby-doc.org/stdlib-1.9.3/libdoc/openssl/rdoc/OpenSSL/Cipher.html
require 'json'
require 'yaml'

# irb -r ./download_key.rb

class DownloadKey
  # inspired by # https://andyatkinson.com/blog/2018/01/22/encrypt-decrypt-ruby

  PATH_TO_SECRETS_YAML = "/Users/gmc/Code/board_game_dot_new/.secrets.yaml"

  attr_reader :email

  def initialize(topic, email)
    raise ArgumentError, "must pass a String for topic" unless topic.is_a?(String)
    raise ArgumentError, "must pass a String for email" unless email.is_a?(String)
    @topic = topic
    @email = email
  end

  def encrypted_download_key
    @encrypted_download_key ||= encrypt_hash({
      :topic => @topic,
      :email => @email
    })
  end

  def self.decrypt_to_hash(string)
    raise ArgumentError, "must pass an encrypted String" unless string.is_a?(String)
    decryptor_cipher = OpenSSL::Cipher::AES.new(256, :CBC).tap do |c|
      ensure_cipher_keys_are_saved_to_environment
      c.decrypt
      c.key = Base64.urlsafe_decode64(ENV['GAME_DOWNLOAD_LINK_CIPHER_KEY_BASE_64'])
      c.iv  = Base64.urlsafe_decode64(ENV['GAME_DOWNLOAD_LINK_CIPHER_IV_BASE_64'])
    end
    JSON.parse(
      decryptor_cipher.update(Base64.urlsafe_decode64(string)) +
      decryptor_cipher.final # CBC operates on fixed-size blocks of data, and therefore it requires a "finalization" step to produce or correctly decrypt the last block of data by appropriately handling some form of padding. read more here: https://ruby-doc.org/stdlib-2.4.0/libdoc/openssl/rdoc/OpenSSL/Cipher.html#class-OpenSSL::Cipher-label-Calling+Cipher-23final
    ).transform_keys(&:to_sym)
  end


  def self.generate_new_base_64_encoded_cipher_key_and_iv
    cipher = OpenSSL::Cipher::AES.new(256, :CBC)
    puts
    puts "Key: #{Base64.urlsafe_encode64(cipher.random_key)}"
    puts " IV: #{Base64.urlsafe_encode64(cipher.random_key)}"
    puts
    puts "Don't forget to copy these and update .secrets.yaml!"
    puts
  end

  def self.save_base_64_encoded_cipher_key_and_iv_to_environment
    YAML.load(File.read(PATH_TO_SECRETS_YAML)).tap do |keys|
      ENV['GAME_DOWNLOAD_LINK_CIPHER_KEY_BASE_64'] = keys['GAME_DOWNLOAD_LINK_CIPHER_KEY_BASE_64']
      ENV['GAME_DOWNLOAD_LINK_CIPHER_IV_BASE_64']  = keys['GAME_DOWNLOAD_LINK_CIPHER_IV_BASE_64']
    end
  end


  private


  def self.ensure_cipher_keys_are_saved_to_environment
    DownloadKey.save_base_64_encoded_cipher_key_and_iv_to_environment if [
      ENV['GAME_DOWNLOAD_LINK_CIPHER_KEY_BASE_64'].nil?, 
      ENV['GAME_DOWNLOAD_LINK_CIPHER_IV_BASE_64'].nil?
    ].any? 
  end

  def encryptor_cipher
    @encryptor_cipher ||= OpenSSL::Cipher::AES.new(256, :CBC).tap do |c|
      DownloadKey.ensure_cipher_keys_are_saved_to_environment
      c.encrypt
      c.key = Base64.urlsafe_decode64(ENV['GAME_DOWNLOAD_LINK_CIPHER_KEY_BASE_64'])
      c.iv  = Base64.urlsafe_decode64(ENV['GAME_DOWNLOAD_LINK_CIPHER_IV_BASE_64'])
    end
  end

  def encrypt_hash(hash)
    raise ArgumentError, "must pass a Hash, or an object that responds to .to_json" unless hash.respond_to?(:to_json)
    Base64.urlsafe_encode64(
      encryptor_cipher.update(hash.to_json) + 
      encryptor_cipher.final # CBC operates on fixed-size blocks of data, and therefore it requires a "finalization" step to produce or correctly decrypt the last block of data by appropriately handling some form of padding. read more here: https://ruby-doc.org/stdlib-2.4.0/libdoc/openssl/rdoc/OpenSSL/Cipher.html#class-OpenSSL::Cipher-label-Calling+Cipher-23final
    )
  end

end
