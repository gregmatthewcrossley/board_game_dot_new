class BoardGame

  # load the gems in 'Gemfile'
  require 'bundler/setup'
  Bundler.require(:default)

  # load all the other ruby files
  require 'require_all' # https://github.com/jarmo/require_all
  require_rel '../lib/**/*.rb'

  include GamePdfGenerator

  GAME_COMPONENTS = %w(
    assembly_instructions
    game_board
    game_box
    question_cards
    chance_cards
    game_instructions
    game_money
    game_pieces
  )

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
    @analyzed_text ||= ExternalTextAnalyzer::GoogleNaturalLanguage.new(@text).analysis
    
    # save or retrieve the main image URL
    @main_image_url ||= ExternalImageSource::WikipediaApi.new(@topic).url
  end

  def assembly_instructions
    @assembly_instructions ||= AssemblyInstructions.new(@topic).generate
  end

  def game_board
    @game_board ||= GameBoard.new(@analyzed_text).generate
  end

  def game_box
    @game_box ||= GameBox.new(@main_image_url).generate
  end

  def question_cards
    @question_cards ||= QuestionCards.new(@analyzed_text).generate
  end

  def chance_cards
    @chance_cards ||= ChanceCards.new(@analyzed_text).generate
  end

  def game_instructions
    @game_instructions ||= GameInstructions.new(@analyzed_text).generate
  end

  def game_money
    @game_money ||= GameMoney.new(@topic).generate
  end

  def game_pieces
    @game_pieces ||= GamePieces.new(@analyzed_text).generate
  end 

  def generate
    # generates all game content
    GAME_COMPONENTS.each do |component|
      send component
    end
    return self
  end 

end