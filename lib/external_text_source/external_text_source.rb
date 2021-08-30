module ExternalTextSource

  MINIMUM_WORDS_FOR_TEXT_SOURCE = 1000
  EXTERNAL_STORAGE_FILENAME = 'text_source.txt'

  class Any

    # This class is a parent class that loads multiple specific sources
    # and, after attempting to initialize all of them, attempts to 
    # pick and use the best one.

    def self.all_source_classes
      # a convenience method to list all the direct decendants of the Any class
      ObjectSpace.each_object(::Class).select {|klass| klass < self }
    end

    def self.vetted_topics
      all_source_classes.map do |klass|
        klass.vetted_topics
      end.flatten
    end

    attr_reader :title, :source_text, :word_count

    def initialize(topic)
      # validate the topic argument
      raise ArgumentError, "must pass a topic (a non-empty String)" unless topic.is_a?(String) && !topic.empty?
      @topic = topic

      # check persistant storage, use this if it exists
      if saved_text_source_hash = ExternalPersistentStorage.retrieve_hash(@topic, EXTERNAL_STORAGE_FILENAME)
        # set the accessor attributes
        @title       = saved_text_source_hash[:title]
        @source_text = saved_text_source_hash[:source_text]
        @word_count  = saved_text_source_hash[:word_count]
      else
        # try to initialize each subclass
        all_sources = Any.all_source_classes.map do |klass|
          klass.new(@topic) rescue nil
        end.compact
        raise ArgumentError, "no external text source found for '#{@topic}'" if all_sources.empty?

        # take the one with the longest text
        sources_and_word_counts = all_sources.map do |source|
          [source, source.word_count]
        end.to_h
        best_source = sources_and_word_counts.key(sources_and_word_counts.values.max)

        # set the accessor attributes
        @title       = best_source.title
        @source_text = best_source.source_text
        @word_count  = best_source.word_count

        # attempt to store the text source
        ExternalPersistentStorage.save_hash(
          @topic, 
          EXTERNAL_STORAGE_FILENAME,
          {
            :title => best_source.title,
            :source_text => best_source.source_text,
            :word_count => best_source.word_count
          }
        )
      end
      
    end
    
    def long_enough?
      @word_count >= MINIMUM_WORDS_FOR_TEXT_SOURCE
    end

  end

  class WikipediaApi < Any

    FEATURED_ARTICLE_TITLES = File.read(File.expand_path('featured_article_titles.txt', File.dirname(__FILE__))).split(/\n/)

    def self.vetted_topics
      FEATURED_ARTICLE_TITLES
    end

    attr_reader :title, :source_text, :word_count

    def initialize(topic)
      # validate the topic argument
      raise ArgumentError, "must pass a topic (a non-empty String)" unless topic.is_a?(String) && !topic.empty?
      @topic = topic

      # attempt to retrieve the Wikipedia article
      article = Wikipedia.find(@topic) 
      # try with downcase as a last resort
      article = Wikipedia.find(@topic.downcase) if article.title.nil? || article.text.nil?
      # raise an ArgumentError if the result doesn't include a title and text
      raise ArgumentError, "no Wikipedia article found for '#{@topic}'" if article.title.nil? || article.text.nil?
      @title       = article.title
      @source_text = article.text
      @word_count  = @source_text.split(' ').count

      # clean up the article text
      clean_up_text
    end

    
    private


    def clean_up_text
      # The Wikipedia API sometimes returns two sentences without a space
      # between them (ie when paragraphs end and a new one starts). 
      # This regex will fix such errors:
      @source_text.gsub!(/([A-Za-z][.])([A-Za-z])/, '\1 \2')

      # Remove any paragraph titles (ie '=== History ===')
      @source_text.gsub!(/={2,}(.*?)={2,}\n/, '')
    end

  end

end 