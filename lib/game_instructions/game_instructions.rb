class GameInstructions

  require_rel './pdf/game_instructions_pdf_generator.rb'
  include GameInstructionsPdfGenerator

  # def initialize(analysis_result)
  #   # validate the analysis_result
  #   raise ArgumentError, "must pass an ExternalTextAnalyzer::AnalysisResult" unless analysis_result.is_a?(ExternalTextAnalyzer::AnalysisResult)
  #   @analysis_result = analysis_result
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