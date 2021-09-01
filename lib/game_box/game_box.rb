class GameBox 

  require_rel './pdf/game_box_pdf_generator.rb'
  prepend GameBoxPdfGenerator

  attr_reader :topic, :main_image, :game_name, :game_description

  def initialize(topic)
    # validate the topic argument
    raise ArgumentError, "must pass a topic (a non-empty String)" unless topic.is_a?(String) && !topic.empty?
    @topic = topic
    # get the box's main image
    @main_image = ExternalImageSource::Any.new(@topic).tempfile rescue nil # a Tempfile
    # get the game's name and description
    # initialize the name and description
    NameAndDescription.new(@topic).tap do |n|
      @game_name = n.name
      @game_description = n.description
    end
    raise ArgumentError, "a main image could not be found for '#{@topic}'" if @main_image.nil?
    raise ArgumentError, "@main_image must be a Tempfile" unless @main_image.is_a?(Tempfile)
  end

  def quantity
    1
  end

end