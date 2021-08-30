module ExternalTextAnalyzer

  require 'json'

  # A class that holds a generic analsis result
  class AnalysisResult

    # A construct to hold a generic analysis result

    attr_reader :sentences, :entities

    def initialize(sentences = nil, entities = nil, hash: nil)
      raise ArgumentError, "hash must be a Hash" unless hash.is_a?(Hash) || hash.nil?
      if hash.is_a?(Hash) 
        # if we're creating a new AnalysisResult from a hash (ie from persistant storage)
        raise ArgumentError, "hash must have keys :sentences and :entities" unless hash.keys.include?(:entities) && hash.keys.include?(:sentences)
        @sentences = hash[:sentences].map do |sentence_hash|
          raise ArgumentError, "hash[:sentences] must be an array of Hashes with keys 'string' and 'sentiment'" unless sentence_hash["string"].is_a?(String) && sentence_hash["sentiment"].is_a?(Float)
          Sentence.new(
            sentence_hash["string"], 
            sentence_hash["sentiment"]
          )
        end
        @entities = hash[:entities].map do |entity_hash|
          raise ArgumentError, "hash[:entities] must be an array of Hashes with keys 'string', 'salience', 'type' and 'is_proper'" unless entity_hash["string"].is_a?(String) && entity_hash["salience"].is_a?(Float) && entity_hash["type"].is_a?(String) && [true, false].include?(entity_hash["is_proper"])
          Entity.new(
            entity_hash["string"], 
            entity_hash["salience"], 
            entity_hash["type"].to_sym, 
            entity_hash["is_proper"]
          )
        end
      else
        # or else if we're creating a new AnalysisResult the regular way
        raise ArgumentError, 'sentences must be an array containing only Sentence(s)' unless sentences.is_a?(Array) && sentences.map { |s| s.is_a?(ExternalTextAnalyzer::Sentence) }.all?
        @sentences = sentences
        raise ArgumentError, 'entities must be an array containing only Entity(s)' unless entities.is_a?(Array) && entities.map { |s| s.is_a?(ExternalTextAnalyzer::Entity) }.all?
        @entities = entities
      end
    end

    def to_h
      {
        "sentences" => @sentences.map(&:to_h),
        "entities"  => @entities.map(&:to_h)
      }
    end

  end

  class Sentence

    # One of two parts of a generic analysis result (AnalysisResult)

    attr_reader :string, :sentiment

    def initialize(string, sentiment)
      raise ArgumentError, "string must be a String" unless string.is_a?(String) && !string.empty?
      raise ArgumentError, "string must end with a period, question mark or exclamation mark" unless %w(. ? ! ").include?(string[-1])
      @string = string
      raise ArgumentError, "sentiment must be a number between -1.0 and 1.0" unless (-1.0..1.0).include?(sentiment)
      @sentiment = sentiment
    end

    def to_h
      {
        "string"    => @string,
        "sentiment" => @sentiment
      }
    end

  end

  class Entity

    # One of two parts of a generic analysis result (AnalysisResult)

    ENTITY_TYPE_WHITELIST = %w(
      PERSON
      LOCATION
      ORGANIZATION
      EVENT
      WORK_OF_ART
      CONSUMER_GOOD
      DATE
    ).map(&:to_sym)

    attr_reader :string, :salience, :type, :is_proper

    def initialize(string, salience, type, is_proper)
      raise ArgumentError, "string must be a String" unless string.is_a?(String) && !string.empty?
      @string = string
      raise ArgumentError, "salience must be a number between 0.0 and 1.0" unless (0.0..1.0).include?(salience)
      @salience = salience
      raise ArgumentError, "type must be one of #{ENTITY_TYPE_WHITELIST}" unless ENTITY_TYPE_WHITELIST.include?(type)
      @type = type
      raise ArgumentError, "is_proper must be either true or false" unless [true, false].include?(is_proper)
      @is_proper = is_proper
    end

    alias_method :is_proper?, :is_proper

    def to_h
      {
        "string"    => @string,
        "salience"  => @salience,
        "type"      => @type,
        "is_proper" => @is_proper
      }
    end

  end

end