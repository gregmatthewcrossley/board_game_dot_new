class ChanceCards
  require_rel '/pdf/chance_cards_pdf_generator.rb'
  include ChanceCardsPdfGenerator
  
  DEFAULT_NUMBER_OF_CHANCES = 25
  POSITIVE_CONSEQUENCE_LIST = [
      "Move forward * spaces.",
      "Take * dollars from the pot.",
      "Everyone gives you * dollars.",
    ]
  NEGATIVE_CONSEQUENCE_LIST = [
      "Move back * spaces.",
      "Pay * dollars to the pot.",
      "Pay everyone * dollars."
    ]
  CONSEQUENCE_RANGE = 5

  attr_reader :all

  def initialize(analyzed_text, number_of_chances = DEFAULT_NUMBER_OF_CHANCES)
    raise ArgumentError, "number_of_chances must be a non-zero Integer" unless number_of_chances.is_a?(Integer) && number_of_chances > 0
    @number_of_chances = number_of_chances
    raise ArgumentError, 'must pass an ExternalTextAnalyzer::AnalysisResult when initializing' unless analyzed_text.is_a?(ExternalTextAnalyzer::AnalysisResult)
    @analyzed_text = analyzed_text
    
    # initialize an empty 'all' array (populated by the 'generate' method below)
    @all = []
  end

  def generate
    return self unless @all.empty?
    @all = @analyzed_text.sentences.map { |sentence| 
      Struct.new(:event, :consequence, :sentiment).new(
        sentence.string, 
        consequence_from(sentence.sentiment), 
        sentence.sentiment
      )
    }.sort { |a, b| # put the most interesting events first
      a.sentiment.abs <=> b.sentiment.abs
    }.take(@number_of_chances)
    .shuffle

    return self
  end


  private


  def consequence_from(sentiment)
    raise ArgumentError, "sentiment must be a number between -1.0 and 1.0" unless (-1.0..1.0).include?(sentiment)
    consequence_list = sentiment.positive? ? POSITIVE_CONSEQUENCE_LIST : NEGATIVE_CONSEQUENCE_LIST
    consequence_list.sample.gsub('*', consequence_value(sentiment))
  end

  def consequence_value(sentiment)
    raise ArgumentError, "sentiment must be a number between -1.0 and 1.0" unless (-1.0..1.0).include?(sentiment)
    (CONSEQUENCE_RANGE*sentiment).round.to_i.abs.to_s
  end

end