module ExternalTextSource

  MINIMUM_WORDS_FOR_TEXT_SOURCE = 1000

  class Any

    SOURCES = [::WikipediaApi]

    def self.vetted_topics
      SOURCES.map do |klass|
        klass.vetted_topics
      end.flatten
    end

    attr_reader :title, :text, :word_count

    def initialize(topic)
      binding.pry
      # validate the topic argument
      raise ArgumentError, "must pass a topic (a non-empty String)" unless topic.is_a?(String) && !topic.empty?

      # check persistant storage
      # TO-DO

      # try to initialize each subclass
      all_sources = SOURCES.map do |klass|
        klass.new(topic) rescue nil
      end.compact
      raise ArgumentError, "no external text source found for '#{topic}'" if all_sources.empty?

      # take the one with the longest text
      best_source = all_sources.map do |source|
        [source, source.word_count]
      end.to_h.key(hash.values.max)

      # set the attributes
      @title      = best_source.title
      @text       = best_source.text
      @word_count = best_source.word_count
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

    attr_reader :title, :text, :word_count

    def initialize(topic)
      # validate the topic argument
      raise ArgumentError, "must pass a topic (a non-empty String)" unless topic.is_a?(String) && !topic.empty?
      
      # attempt to retrieve the Wikipedia article
      article = Wikipedia.find(topic) 
      # try with downcase as a last resort
      article = Wikipedia.find(topic.downcase) if article.title.nil? || article.text.nil?
      # raise an ArgumentError if the result doesn't include a title and text
      raise ArgumentError, "no Wikipedia article found for '#{topic}'" if article.title.nil? || article.text.nil?
      @title      = article.title
      @text       = article.text
      @word_count = @text.split(' ').count

      # clean up the article text
      clean_up_text
    end

    
    private


    def clean_up_text
      # The Wikipedia API sometimes returns two sentences without a space
      # between them (ie when paragraphs end and a new one starts). 
      # This regex will fix such errors:
      @text.gsub!(/([A-Za-z][.])([A-Za-z])/, '\1 \2')

      # Remove any paragraph titles (ie '=== History ===')
      @text.gsub!(/={2,}(.*?)={2,}\n/, '')
    end

  end

end 