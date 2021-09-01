class ChanceCards
  require_rel '/pdf/chance_cards_pdf_generator.rb'
  prepend ChanceCardsPdfGenerator
  
  NUMBER_OF_CHANCE_CARDS = 5 # 25
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

  EXTERNAL_STORAGE_FILENAME = 'chance_cards.json'

  attr_reader :topic, :analysis_result, :chance_cards

  def initialize(topic)
    # validate the topic argument
    raise ArgumentError, "must pass a topic (a non-empty String)" unless topic.is_a?(String) && !topic.empty?
    @topic = topic
    @analysis_result = ExternalTextAnalyzer::Any.new(@topic).analysis_result
    raise ArgumentError, "no ExternalTextAnalyzer::AnalysisResult could be found for #{@topic}" unless @analysis_result.is_a?(ExternalTextAnalyzer::AnalysisResult)
    unless @analysis_result.sentences.count >= NUMBER_OF_CHANCE_CARDS
      raise ArgumentError, "text must have at least " + NUMBER_OF_CHANCE_CARDS.to_s + " sentences"
    end
    @chance_cards = retrieve_chance_cards || generate_chance_cards
  end

  def quantity
    NUMBER_OF_CHANCE_CARDS
  end


  private


  def retrieve_chance_cards
    ExternalPersistentStorage.retrieve_hash(@topic, EXTERNAL_STORAGE_FILENAME)
  end

  def generate_chance_cards
    @analysis_result.sentences.map { |sentence| 
      Struct.new(:event, :consequence, :sentiment).new(
        sentence.string, 
        consequence_from(sentence.sentiment), 
        sentence.sentiment
      )
    }.sort { |a, b| # put the most interesting events first
      a.sentiment.abs <=> b.sentiment.abs
    }.take(NUMBER_OF_CHANCE_CARDS)
    .shuffle
  end


  private


  def consequence_from(sentiment)
    raise ArgumentError, "sentiment must be a number between -1.0 and 1.0" unless (-1.0..1.0).include?(sentiment)
    consequence_list = sentiment.positive? ? POSITIVE_CONSEQUENCE_LIST : NEGATIVE_CONSEQUENCE_LIST
    consequence_list.sample.gsub('*', consequence_value(sentiment))
  end

  def consequence_value(sentiment)
    raise ArgumentError, "sentiment must be a number between -1.0 and 1.0" unless (-1.0..1.0).include?(sentiment)
    ((CONSEQUENCE_RANGE*sentiment).round.to_i.abs + 1).to_s
  end

end