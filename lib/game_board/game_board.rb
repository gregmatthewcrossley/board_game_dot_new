class GameBoard

  require 'terminal-table'

  PLACE_COUNT = 100
  CHANCE_PLACE_COUNT = 10
  QUESTION_PLACE_COUNT = 10
  LADDER_PLACE_COUNT = 10
  CHUTE_PLACE_COUNT = 10
  TOO_CLOSE = 2
  TOO_FAR = (PLACE_COUNT / 10).to_i

  # time_per_regular_turn = 10
  # chance_delta = 20
  # question_delta = 20
  # question_odds = 0.5

  def initialize()

    # create places array
    @places = (1..PLACE_COUNT).map { |i| [i, :blank]}.to_h

    def blank_place_indicies
      @places.select { |i, v| v == :blank}.map { |i, v| i }
    end

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
    end

    # add chutes
    blank_place_indicies.sample(CHUTE_PLACE_COUNT).each do |i|
      @places[i] = {
        :chute_to => blank_place_indicies.select { |j| 
          (i - j) > TOO_CLOSE &&
          (i - j) < TOO_FAR
        }.sample
      }
    end

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
          "#{k}\n#{v.to_s}"
        }
      end
      t.style = {:all_separators => true}
    end

    puts table

  end

end

# pry -r './game_board.rb' -e 'GameBoard.new.print'
