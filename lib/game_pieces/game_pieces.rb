class GamePieces

  require_rel '/pdf/game_pieces_pdf_generator.rb'
  include GamePiecesPdfGenerator

  NUMBER_OF_GAME_PIECES = 8

  USEABLE_ENTITY_TYPE_WHITELIST = %w(
      PERSON
      LOCATION
      ORGANIZATION
      WORK_OF_ART
    ).map(&:to_sym)

  EXTERNAL_STORAGE_FILENAME = 'game_pieces.json'

  attr_reader :topic, :analysis_result, :game_pieces

  def initialize(topic)
    # validate the topic argument
    raise ArgumentError, "must pass a topic (a non-empty String)" unless topic.is_a?(String) && !topic.empty?
    @topic = topic
    # validate analysis result
    @analysis_result = ExternalTextAnalyzer::Any.new(@topic).analysis_result
    raise ArgumentError, "no ExternalTextAnalyzer::AnalysisResult could be found for #{@topic}" unless @analysis_result.is_a?(ExternalTextAnalyzer::AnalysisResult)
    # retrieve or generate game pieces
    @game_pieces = retrieve_game_pieces || generate_game_pieces
  end

  def quantity
    NUMBER_OF_GAME_PIECES
  end


  private


  def retrieve_game_pieces
    return nil unless game_piece_hash = ExternalPersistentStorage.retrieve_hash(@topic, EXTERNAL_STORAGE_FILENAME)
    game_piece_hash.each do |i, game_piece_name|
      # ensure each of the game pieces has an image loaded (and if not, re-find one)
      ExternalImageSource::Any.new(game_piece_name)
    end
  end

  def generate_game_pieces
    # select proper nouns (from analysis results) to be game pieces
    proper_noun_entities = @analysis_result.entities
      .select { |e| # keep only specific types of proper nouns
        USEABLE_ENTITY_TYPE_WHITELIST.include?(e.type) && e.is_proper?
      }.sort_by(&:salience).reverse! # move the most interesting proper nouns to the top
    raise ArgumentError, "not enough proper noun entities to create game pieces (need #{NUMBER_OF_GAME_PIECES}, but found #{proper_noun_entities.count})" unless proper_noun_entities.count >= NUMBER_OF_GAME_PIECES
    # generate game pieces
    {}.tap do |game_pieces|
      proper_noun_entities.each do |e|
        break if game_pieces.count == NUMBER_OF_GAME_PIECES
        capitalized_name = e.string.split.map(&:capitalize).join(' ')
        if (ExternalImageSource::Any.new(capitalized_name) rescue nil)
          # if an image can be found (and by finding it, it gets stored for reuse later)
          # then add a new game piece
          game_pieces[game_pieces.count + 1] = capitalized_name
        end
      end
      # save game_pieces hash to persistant storage (TO-DO!)
      ExternalPersistentStorage.save_hash(@topic, EXTERNAL_STORAGE_FILENAME, game_pieces)
    end
  end

end