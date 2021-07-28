class GameBox 

  require_rel './pdf/game_box_pdf_generator.rb'
  include GameBoxPdfGenerator

  # attr_reader :image_url

  def initialize(topic)
    # get the box's main image
    # raise ArgumentError, "must pass an image_url string" unless image_url.is_a?(String) && !image_url.empty?
    # @image_url = image_url

    # validate the topic argument
    raise ArgumentError, "must pass a topic (a non-empty String)" unless topic.is_a?(String) && !topic.empty?
    @topic = topic
  end

  def preview_image
    "foo bar" #TO-DO: make this an image
  end

  def generate
    return self
  end

end