class BoardGame

  # load the gems in 'Gemfile'
  require 'bundler/setup'
  Bundler.require(:default)

  # load all the other ruby files
  require 'require_all' # https://github.com/jarmo/require_all
  require_rel '../lib/**/*.rb'

  attr_reader :topic, :name, :description 

  def initialize(topic, text: nil)
    raise ArgumentError, 'must pass a topic (string) when initializing' unless topic.is_a?(String) && !topic.empty?

    # save the topic
    @topic = topic.split().map(&:capitalize).join(' ')

    # generate a random name and description
    NameAndDescription.new(@topic).tap do |n|
      @name = n.name
      @description = n.description
    end

    # save or retrieve the text content
    @text ||= ExternalTextSource::WikipediaApi.new(@topic).text

    # analyze the text
    @analyzed_text = ExternalTextAnalyzer::GoogleNaturalLanguage.new(@text).analysis
  end

  def game_board
    @game_board ||= GameBoard.new
  end

  def game_box
    @game_box ||= GameBox.new(@topic)
  end

  def game_pieces
    @game_pieces ||= GamePieces.new(@analyzed_text).all
  end

  def question_cards
    @question_cards ||= CardSet::Question.new(@analyzed_text).generate
  end

  def chance_cards 
    @chance_cards ||= CardSet::Chance.new(@analyzed_text).generate
  end

end