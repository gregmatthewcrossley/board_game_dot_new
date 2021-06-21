class BoardGame

  # load the gems in 'Gemfile'
  require 'bundler/setup'
  Bundler.require(:default)

  # load all the other ruby files
  require 'require_all' # https://github.com/jarmo/require_all
  require_rel '../lib/**/*.rb'
  require 'date'

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

  # GAME_COMPONENTS = ["game_money"]

  attr_reader :topic, :name, :description, :download_key

  def initialize(topic, text: nil)
    raise ArgumentError, 'must pass a topic (string) when initializing' unless topic.is_a?(String) && !topic.empty?

    # save the topic
    @topic = topic

    # generate a random name and description
    NameAndDescription.new(@topic).tap do |n|
      @name = n.name
      @description = n.description
    end
    
    # save or retrieve the text content
    BoardGame.log_elapsed_time_for("text retrieval for '#{@topic}'") do
      @text ||= ExternalTextSource::WikipediaApi.new(@topic).text
    end

    # analyze the text
    BoardGame.log_elapsed_time_for("text analysis for '#{@topic}'") do
      @analyzed_text ||= ExternalTextAnalyzer::GoogleNaturalLanguage.new(@text).analysis
    end

    # save or retrieve the main image URL
    BoardGame.log_elapsed_time_for("main image sourcing for '#{@topic}'") do
      @main_image_url ||= ExternalImageSource::WikipediaApi.new(@topic).url
    end
  
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
      BoardGame.log_elapsed_time_for("#{component} generation for '#{@topic}'") do
        send component
      end
    end
    return self
  end

  def self.log_elapsed_time_for(description)
    # raise ArgumentError, "description must be a String" unless description.is_a?(String)
    # starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    # ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    # elapsed = ending - starting
    # puts "#{elapsed.round(1)}s".ljust(8) +"#{description}."
  end

end