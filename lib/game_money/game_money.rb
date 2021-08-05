class GameMoney

  NUMBER_OF_MONEYS = 100

  require_rel './pdf/game_money_pdf_generator.rb'
  include GameMoneyPdfGenerator

  attr_reader :topic

  def initialize(topic)
    # validate the topic argument
    raise ArgumentError, "must pass a topic (a non-empty String)" unless topic.is_a?(String) && !topic.empty?
    @topic = topic
  end

  def quantity
    NUMBER_OF_MONEYS
  end

end