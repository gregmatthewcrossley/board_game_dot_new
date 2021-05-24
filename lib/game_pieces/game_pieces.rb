class GamePieces

  NUMBER_OF_PIECES = 8

  USEABLE_ENTITY_TYPE_WHITELIST = %w(
      PERSON
      LOCATION
      ORGANIZATION
      WORK_OF_ART
    ).map(&:to_sym)

  attr_reader :all

  def initialize(analysis_result)
    # validate the analysis_result
    raise ArgumentError, "must pass an ExternalTextAnalyzer::AnalysisResult" unless analysis_result.is_a?(ExternalTextAnalyzer::AnalysisResult)
    @analysis_result = analysis_result

    # find proper nouns for pieces
    proper_noun_entities = @analysis_result.entities
      .select { |e| # keep only specific types of proper nouns
        USEABLE_ENTITY_TYPE_WHITELIST.include?(e.type) && e.is_proper?
      }.sort_by(&:salience).reverse!
    raise ArgumentError, "not enough proper noun entities to create game pieces (need #{NUMBER_OF_PIECES}, but found #{proper_noun_entities.count})" unless proper_noun_entities.count >= NUMBER_OF_PIECES
    
    # select and create pieces
    @all = []
    proper_noun_entities.each do |e|
      break if @all.count == NUMBER_OF_PIECES
      capitalized_name = e.string.split.map(&:capitalize).join(' ')
      found_url = ExternalImageSource::WikipediaApi.new(capitalized_name).url rescue nil
      unless found_url.nil?
        @all << Struct.new(:name, :image_url).new(
          capitalized_name,
          found_url
        )
      end
    end
  end

end