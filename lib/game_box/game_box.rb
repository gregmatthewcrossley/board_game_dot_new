class GameBox

  require_rel './pdf/game_box_pdf_generator.rb'
  include GameBoxPdfGenerator

  attr_reader :image_url

  def initialize(topic)
    # validate the topic argument
    raise ArgumentError, "must pass a topic (a non-empty String)" unless topic.is_a?(String) && !topic.empty?
    @topic = topic

    # get the box's main image
    @image_url = ExternalImageSource::WikipediaApi.new(@topic).url
    raise ArgumentError, "no box image could be found for '#{@topic}'" unless @image_url.is_a?(String) && !@image_url.empty?
  end

  def generate
    return self
  end

end