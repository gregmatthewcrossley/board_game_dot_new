class GameMoney

  require_rel './pdf/game_money_pdf_generator.rb'
  include GameMoneyPdfGenerator

  # def initialize(topic)
  #   raise ArgumentError, 'must pass a topic (string) when initializing' unless topic.is_a?(String) && !topic.empty?
  #   # save the topic
  #   @topic = topic.split().map(&:capitalize).join(' ')
  # end

  def initialize(topic)
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