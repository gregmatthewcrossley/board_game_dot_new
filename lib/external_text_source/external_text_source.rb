module ExternalTextSource

  MINIMUM_WORDS_FOR_TEXT_SOURCE = 1000

  class WikipediaApi

    FEATURED_ARTICLE_TITLES = File.read(File.expand_path('featured_article_titles.txt', File.dirname(__FILE__))).split(/\n/)

    attr_reader :text, :title

    def initialize(topic)
      # validate the topic argument
      raise ArgumentError, "must pass a topic (a non-empty String)" unless topic.is_a?(String) && !topic.empty?
      
      # attempt to retrieve the Wikipedia article
      article = Wikipedia.find(topic.downcase) # downcased topics seem to work best
      raise ArgumentError, "no Wikipedia article found for '#{topic}'" if article.title.nil? || article.text.nil?
      @title = article.title
      @text = article.text

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