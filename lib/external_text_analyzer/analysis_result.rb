module ExternalTextAnalyzer

  require 'json'

  # A class that holds a generic analsis result
  class AnalysisResult

    # A construct to hold a generic analysis result

    attr_reader :sentences, :entities

    def initialize(sentences, entities)
      raise ArgumentError, 'sentences must be an array containing only Sentence(s)' unless sentences.is_a?(Array) && sentences.map { |s| s.is_a?(ExternalTextAnalyzer::Sentence) }.all?
      @sentences = sentences
      raise ArgumentError, 'entities must be an array containing only Entity(s)' unless entities.is_a?(Array) && entities.map { |s| s.is_a?(ExternalTextAnalyzer::Entity) }.all?
      @entities = entities
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