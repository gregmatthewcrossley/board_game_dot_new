module ExternalTextAnalyzer

  class AnalysisResult

    attr_reader :sentences, :entities

    def initialize(sentences, entities)
      raise ArgumentError, 'sentences must be an array containing only Sentence(s)' unless sentences.is_a?(Array) && sentences.map { |s| s.is_a?(ExternalTextAnalyzer::Sentence) }.all?
      @sentences = sentences
      raise ArgumentError, 'entities must be an array containing only Entity(s)' unless entities.is_a?(Array) && entities.map { |s| s.is_a?(ExternalTextAnalyzer::Entity) }.all?
      @entities = entities
    end

  end

  class Sentence

    attr_reader :string, :sentiment

    def initialize(string, sentiment)
      raise ArgumentError, "string must be a String" unless string.is_a?(String) && !string.empty?
      raise ArgumentError, "string must end with a period, question mark or exclamation mark" unless %w(. ? ! ").include?(string[-1])
      @string = string
      raise ArgumentError, "sentiment must be a number between -1.0 and 1.0" unless (-1.0..1.0).include?(sentiment)
      @sentiment = sentiment
    end

  end

  class Entity

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

  end

  class GoogleNaturalLanguage

    # save the location of the JSON file containing the app's 
    # google app credentials as an environment variable
    ENV["GOOGLE_APPLICATION_CREDENTIALS"] = "google_application_credentials.json" 

    def initialize(text)
      raise ArgumentError, 'must pass text (String) when initializing' unless text.is_a?(String)
      @text = text

      # initiate Google Cloud Language client
      @client = Google::Cloud::Language.language_service
    end

    def analysis
      # https://googleapis.dev/ruby/google-cloud-language-v1/latest/Google/Cloud/Language/V1/LanguageService/Client.html#annotate_text-instance_method
      @analysis_response ||= @client.annotate_text(
        document: {
          content: @text, 
          type: :PLAIN_TEXT
        },
        features: {
          classify_text:              false,
          extract_document_sentiment: true,
          extract_entities:           true,
          extract_entity_sentiment:   false,
          extract_syntax:             true
        })

      @analysis_result ||= AnalysisResult.new(
          @analysis_response.sentences.select { |s|
            %w(. ? ! ").include?(s.text.content[-1]) # drop any sentences that aren't punctuated
          }.map { |s|
            Sentence.new(
              s.text.content, 
              s.sentiment.score
            )
          },
          @analysis_response.entities.select { |e|
            ExternalTextAnalyzer::Entity::ENTITY_TYPE_WHITELIST.include?(e.type) # drop any entities of the wrong type
          }.map { |e|
            Entity.new(
              e.name, 
              e.salience,
              e.type.to_sym, 
              (e.mentions.first['type'] == :PROPER)
            )
          }.uniq { |e| # remove any duplicates
            e.string
          }
        )
    end

  end

end