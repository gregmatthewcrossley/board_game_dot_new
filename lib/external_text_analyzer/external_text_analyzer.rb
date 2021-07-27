module ExternalTextAnalyzer

  class Any

    # This class is a parent class that loads multiple specific sources
    # and, after attempting to initialize all of them, attempts to 
    # pick and use the best one.

    def self.all_source_classes
      # a convenience method to list all the direct decendants of the Any class
      ObjectSpace.each_object(::Class).select {|klass| klass < self }
    end

    attr_reader :analysis_result

    def initialize(topic, source_text = nil)
      # validate the topic argument
      raise ArgumentError, "must pass a topic (a non-empty String)" unless topic.is_a?(String) && !topic.empty?
      @topic = topic
      binding.pry
      # check persistant storage, use this if it exists
      saved_analysis_result = ExternalPersistentStorage.retrieve_analysis_result(@topic) # a Struct that responds to :sentences and :entities
      if saved_analysis_result
        best_source = Struct.new(:analysis_result).new(
            saved_analysis_result
          )
      else
        # validate the source_text
        raise ArgumentError, 'must pass source_text (String) when initializing a topic for the first time' unless source_text.is_a?(String)
        @source_text = source_text

        # try to initialize each subclass
        all_sources = Any.all_source_classes.map do |klass|
          klass.new(@source_text) rescue nil # sources that fail to initialize with the given source_text will be represented by nil
        end.compact # remove the nil (errored) sources
        raise ArgumentError, "no external analysis sources found for '#{@topic}'" if all_sources.empty?

        # take the first source with an AnalysisResult
        best_source = all_sources.select do |s|
          s.analysis_result.is_a?(AnalysisResult)
        end.first
        raise ArgumentError, "none of the external analysis sources returned a AnalysisResult for '#{@topic}'" if best_source.nil?

        # attempt to store the AnalysisResult
        ExternalPersistentStorage.save_analysis_result(
          @topic,
          best_source.analysis_result.sentences.map(&:to_h),
          best_source.analysis_result.entities.map(&:to_h),
        )
      end

      # set the accessor attribute
      @analysis_result = best_source.analysis_result
    end

  end


  class GoogleNaturalLanguage < Any

    attr_reader :analysis_result

    def initialize(text)
      raise ArgumentError, 'must pass text (String) when initializing' unless text.is_a?(String)
      @text = text

      # initiate Google Cloud Language client
      begin
        @client = Google::Cloud::Language.language_service
      rescue RuntimeError => e
        raise e, "#{e.message} \n\nHint: check to see whether an environment variable called 'GOOGLE_APPLICATION_CREDENTIALS' contains a path to a JSON file with those credentials."
      end

      # request an analysis of the provided text
      # https://googleapis.dev/ruby/google-cloud-language-v1/latest/Google/Cloud/Language/V1/LanguageService/Client.html#annotate_text-instance_method
      @analysis_response = @client.annotate_text(
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

      # parse the result into an AnalysisResult
      @analysis_result = AnalysisResult.new(
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
    end # end initialize method

  end # end GoogleNaturalLanguage class

end # end ExternalTextAnalyzer module