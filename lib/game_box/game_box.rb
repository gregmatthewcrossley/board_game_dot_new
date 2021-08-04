class GameBox 

  require_rel './pdf/game_box_pdf_generator.rb'
  include GameBoxPdfGenerator

  attr_reader :main_image

  def initialize(topic)
    # validate the topic argument
    raise ArgumentError, "must pass a topic (a non-empty String)" unless topic.is_a?(String) && !topic.empty?
    @topic = topic
    # get the box's main image
    @main_image = ExternalImageSource::Any.new(@topic).tempfile rescue nil # a Tempfile
    raise ArgumentError, "a main image could not be found for '#{@topic}'" if @main_image.nil?
    raise ArgumentError, "@main_image must be a Tempfile" unless @main_image.is_a?(Tempfile)
  end

end