class GameInstructions

  require_rel './pdf/game_instructions_pdf_generator.rb'
  include GameInstructionsPdfGenerator

  attr_reader :topic

  def initialize(topic)
    # validate the topic argument
    raise ArgumentError, "must pass a topic (a non-empty String)" unless topic.is_a?(String) && !topic.empty?
    @topic = topic
  end

  def quantity
    1
  end

end