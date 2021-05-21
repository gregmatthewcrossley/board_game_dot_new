module ExternalImageSource

  class WikipediaApi

    attr_reader :url

    def initialize(topic)
      # validate the topic argument
      raise ArgumentError, "must pass a topic (a non-empty String)" unless topic.is_a?(String) && !topic.empty?
      @topic = topic

      # attempt to retrieve the Wikipedia article
      @article = Wikipedia.find(@topic)
      raise ArgumentError, "no Wikipedia article found for '#{@topic}'" if @article.title.nil?
      raise ArgumentError, "Wikipedia article '#{@article.title}' has no main image" if @article.main_image_url.nil?

      @url = @article.main_image_url
    end

  end

end 