class GameBoard

  require_rel './pdf/game_board_pdf_generator.rb'
  prepend GameBoardPdfGenerator

  require 'terminal-table'

  PLACE_COUNT = 50
  CHANCE_PLACE_COUNT = PLACE_COUNT / 5
  QUESTION_PLACE_COUNT = PLACE_COUNT / 5
  LADDER_PLACE_COUNT = PLACE_COUNT / 5
  CHUTE_PLACE_COUNT = PLACE_COUNT / 5
  TOO_CLOSE = 2
  TOO_FAR = (PLACE_COUNT / 10).to_i

  EXTERNAL_STORAGE_FILENAME = 'game_board.json'

  attr_reader :topic, :place_map

  def initialize(topic)
    # validate the topic argument
    raise ArgumentError, "must pass a topic (a non-empty String)" unless topic.is_a?(String) && !topic.empty?
    @topic = topic
    @place_map = retrieve_place_map || generate_place_map
  end

  def quantity
    1
  end

  def print
    table = ::Terminal::Table.new do |t|
      square_root = Math.sqrt(@place_map.count).round
      rows = (1..square_root).map { |i| 
        ((square_root * (i-1))+1)..(square_root * i)
      }
      rows.each do |range|
        t.add_row @place_map.select { |k,v| 
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
    # print table to console
    puts table
  end


  private


  def retrieve_place_map
    ExternalPersistentStorage.retrieve_hash(@topic, EXTERNAL_STORAGE_FILENAME)
  end

  def generate_place_map
    # create place_map hash
    (1..PLACE_COUNT).map { |i| [i, :blank]}.to_h.tap do |place_map|

      # add chances
      blank_place_indicies_for(place_map).sample(CHANCE_PLACE_COUNT).each do |i|
        place_map[i] = :chance
      end

      # add questions
      blank_place_indicies_for(place_map).sample(QUESTION_PLACE_COUNT).each do |i|
        place_map[i] = :question
      end

      # add ladders
      blank_place_indicies_for(place_map).sample(LADDER_PLACE_COUNT).each do |i|
        place_map[i] = {
          :ladder_to => blank_place_indicies_for(place_map).select { |j| 
            (j - i) > TOO_CLOSE &&
            (j - i) < TOO_FAR
          }.sample
        }
        # remove any nil chutes
        if place_map[i][:ladder_to].nil?
          place_map[i] = :blank
        end
      end

      # add chutes
      blank_place_indicies_for(place_map).sample(CHUTE_PLACE_COUNT).each do |i|
        place_map[i] = {
          :chute_to => blank_place_indicies_for(place_map).select { |j| 
            (i - j) > TOO_CLOSE &&
            (i - j) < TOO_FAR
          }.sample
        }
        # remove any nil chutes
        if place_map[i][:chute_to].nil?
          place_map[i] = :blank
        end
      end

      # save to storage for next time
      ExternalPersistentStorage.save_hash(@topic, EXTERNAL_STORAGE_FILENAME, place_map)
    end
  end

  def blank_place_indicies_for(place_map)
    place_map.select { |i, v| v == :blank}.map { |i, v| i }
  end

end