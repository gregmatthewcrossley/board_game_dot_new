module ExternalImageSource

  REQUIRED_IMAGE_TYPE_EXTENTION = 'png'
  EXTERNAL_STORAGE_FILENAME = 'main_image.png'

  class Any

    # This class is a parent class that loads multiple specific sources
    # and, after attempting to initialize all of them, attempts to 
    # pick and use the best one.

    def self.all_source_classes
      # a convenience method to list all the direct decendants of the Any class
      ObjectSpace.each_object(::Class).select {|klass| klass < self }
    end

    attr_reader :tempfile

    def initialize(topic)
      # validate the topic argument
      raise ArgumentError, "must pass a topic (a non-empty String)" unless topic.is_a?(String) && !topic.empty?
      @topic = topic

      # check persistant storage, use this if it exists
      saved_image_tempfile = ExternalPersistentStorage.retrieve_file(@topic, EXTERNAL_STORAGE_FILENAME) # a Tempfile of an image
      if saved_image_tempfile.is_a?(Tempfile)
        best_source = Struct.new(:tempfile).new(
            saved_image_tempfile
          )
      else
        # try to initialize each subclass
        all_sources = Any.all_source_classes.map do |klass|
          klass.new(@topic) rescue nil # sources that fail to initialize with the given topic will be represented by nil
        end.compact # remove the nil (errored) sources
        raise ArgumentError, "no external image source found for '#{@topic}'" if all_sources.empty?

        # take the first source with a Tempfile
        best_source = all_sources.select do |s|
          s.tempfile.is_a?(Tempfile)
        end.first
        raise ArgumentError, "none of the external image sources returned a Tempfile for '#{@topic}'" if best_source.nil?

        # attempt to store the image Tempfile
        ExternalPersistentStorage.save_file(
          @topic,
          EXTERNAL_STORAGE_FILENAME,
          best_source.tempfile
        )
      end

      # set the accessor attribute
      @tempfile = best_source.tempfile
    end

  end

  class WikipediaApi < Any

    attr_reader :tempfile

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
      # get the image URL
      @url      = @article.main_image_url
      # download the image, convert to PNG and save to a tempfile
      @tempfile = Tempfile.new([
        EXTERNAL_STORAGE_FILENAME.split('.').first,
        "." + EXTERNAL_STORAGE_FILENAME.split('.').last
      ])
      image = MiniMagick::Image.open(@url)
      image.format "png"
      # save image to instance variable
      image.write(@tempfile.path)
    end

  end

end 