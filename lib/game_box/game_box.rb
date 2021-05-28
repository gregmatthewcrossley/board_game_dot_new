class GameBox

  require_rel './pdf/game_box_pdf_generator.rb'
  include GameBoxPdfGenerator

  attr_reader :image_url

  def initialize(image_url)
    # get the box's main image
    raise ArgumentError, "must pass an image_url string" unless image_url.is_a?(String) && !image_url.empty?
    @image_url = image_url
  end

  def generate
    return self
  end

end