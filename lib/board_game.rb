class BoardGame

  # load the gems in 'Gemfile'
  require 'bundler/setup'
  Bundler.require(:default)

  # load all the other ruby files
  require 'require_all' # https://github.com/jarmo/require_all
  require_rel '../lib/**/*.rb'
  require 'date'

  prepend GamePdfGenerator

  GAME_COMPONENT_NAMES_AND_CLASSES = {
    "assembly_instructions" => AssemblyInstructions,
    "game_box"              => GameBox,
    "game_instructions"     => GameInstructions,
    "game_board"            => GameBoard,
    "game_pieces"           => GamePieces,
    "game_money"            => GameMoney,
    "question_cards"        => QuestionCards,
    "chance_cards"          => ChanceCards
  }

  def self.game_component_names
    GAME_COMPONENT_NAMES_AND_CLASSES.keys
  end

  def self.game_component_classes
    GAME_COMPONENT_NAMES_AND_CLASSES.values
  end

  # attribute reader methods
  attr_reader :topic, 
              :name_and_description,
              *GAME_COMPONENT_NAMES_AND_CLASSES.keys.map(&:to_sym)
              #:download_key

  # instance methods
  def initialize(topic)
    raise ArgumentError, 'must pass a topic (string) when initializing' unless topic.is_a?(String) && !topic.empty?

    # save the topic attribute
    @topic = topic

    # # save the name/description attribute
    # @name_and_description = NameAndDescription.new(@topic)

    # initialize and save the game component attributes
    GAME_COMPONENT_NAMES_AND_CLASSES.each do |component_name, component_class|
      instance_variable_set("@#{component_name}", component_class.new(@topic))
    end
  
  end

  # def self.log_elapsed_time_for(description)
  #   # raise ArgumentError, "description must be a String" unless description.is_a?(String)
  #   # starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  #   yield
  #   # ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  #   # elapsed = ending - starting
  #   # puts "#{elapsed.round(1)}s".ljust(8) +"#{description}."
  # end

end