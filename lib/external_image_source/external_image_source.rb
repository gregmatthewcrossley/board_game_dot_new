module ExternalImageSource

  class Any

    # This class is a parent class that loads multiple specific sources
    # and, after attempting to initialize all of them, attempts to 
    # pick and use the best one.

    def self.all_source_classes
      # a convenience method to list all the direct decendants of the Any class
      ObjectSpace.each_object(::Class).select {|klass| klass < self }
    end

    attr_reader :url

    def initialize(topic)
      # validate the topic argument
      raise ArgumentError, "must pass a topic (a non-empty String)" unless topic.is_a?(String) && !topic.empty?

      # check persistant storage, use this if it exists
      # TO-DO

      # try to initialize each subclass
      all_sources = Any.all_source_classes.map do |klass|
        klass.new(topic) rescue nil
      end.compact
      raise ArgumentError, "no external source found for '#{topic}'" if all_sources.empty?

      # take the first source with an image URL
      first_source = all_sources.select do |s|
        s.url rescue nil
      end.first

      # set the attributes
      @url = first_source.url
    end

  end

  class WikipediaApi < Any

    attr_reader :url

    def initialize(topic)
      # validate the topic argument
      raise ArgumentError, "must pass a topic (a non-empty String)" unless topic.is_a?(String) && !topic.empty?
      @topic = topic

      # attempt to retrieve the Wikipedia article
      @article = Wikipedia.find(@topic)
      # try with downcase as a last resort
      @article = Wikipedia.find(topic.downcase) if @article.title.nil? || @article.text.nil?
      raise ArgumentError, "no Wikipedia article found for '#{@topic}'" if @article.title.nil?
      raise ArgumentError, "Wikipedia article '#{@article.title}' has no main image" if @article.main_image_url.nil?

      @url = @article.main_image_url
    end

  end

end 