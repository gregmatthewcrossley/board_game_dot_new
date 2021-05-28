class GameBoard

  require_rel './pdf/game_board_pdf_generator.rb'
  include GameBoardPdfGenerator

  require 'terminal-table'

  PLACE_COUNT = 50
  CHANCE_PLACE_COUNT = PLACE_COUNT / 5
  QUESTION_PLACE_COUNT = PLACE_COUNT / 5
  LADDER_PLACE_COUNT = PLACE_COUNT / 5
  CHUTE_PLACE_COUNT = PLACE_COUNT / 5
  TOO_CLOSE = 2
  TOO_FAR = (PLACE_COUNT / 10).to_i

  def initialize(analysis_result)
    # validate the analysis_result
    raise ArgumentError, "must pass an ExternalTextAnalyzer::AnalysisResult" unless analysis_result.is_a?(ExternalTextAnalyzer::AnalysisResult)
    @analysis_result = analysis_result
  end

  def generate
    # create places array
    @places = (1..PLACE_COUNT).map { |i| [i, :blank]}.to_h

    # add chances
    blank_place_indicies.sample(CHANCE_PLACE_COUNT).each do |i|
      @places[i] = :chance
    end

    # add questions
    blank_place_indicies.sample(QUESTION_PLACE_COUNT).each do |i|
      @places[i] = :question
    end

    # add ladders
    blank_place_indicies.sample(LADDER_PLACE_COUNT).each do |i|
      @places[i] = {
        :ladder_to => blank_place_indicies.select { |j| 
          (j - i) > TOO_CLOSE &&
          (j - i) < TOO_FAR
        }.sample
      }
      # remove any nil chutes
      if @places[i][:ladder_to].nil?
        @places[i] = :blank
      end
    end

    # add chutes
    blank_place_indicies.sample(CHUTE_PLACE_COUNT).each do |i|
      @places[i] = {
        :chute_to => blank_place_indicies.select { |j| 
          (i - j) > TOO_CLOSE &&
          (i - j) < TOO_FAR
        }.sample
      }
      # remove any nil chutes
      if @places[i][:chute_to].nil?
        @places[i] = :blank
      end
    end

    return self

  end

  def map
    @places
  end

  def print
    table = ::Terminal::Table.new do |t|
      square_root = Math.sqrt(@places.count).round
      rows = (1..square_root).map { |i| 
        ((square_root * (i-1))+1)..(square_root * i)
      }
      rows.each do |range|
        t.add_row @places.select { |k,v| 
          range.include?(k)
        }.map { |k,v| 
          "#{k}\n\n#{v.to_s}"
        }
      end
      t.style = {
        :all_separators => true, 
        :alignment => :center
      }
    end

    puts table

  end


  private


  def blank_place_indicies
    @places.select { |i, v| v == :blank}.map { |i, v| i }
  end

end