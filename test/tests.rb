require_relative '../lib/board_game.rb'
Bundler.require(:test)
require 'minitest/autorun'

class BoardGameTest < Minitest::Test

  parallelize_me!

  TOPICS = ["Rob Ford"]

  # TOPICS = [
  #   "Chorioactis",
  #   "Francis Walsingham",
  #   "Albert Einstein",
  #   "Rob Ford",
  #   "Rome",
  #   "World War Two",
  # ]

  # # Initialization Tests
  # def test_game_creation_requires_a_topic
  #   assert_raises(ArgumentError) { BoardGame.new }
  # end

  # def test_game_creation_fails_on_obscure_topic
  #   assert_raises(ArgumentError) { BoardGame.new("buiwfubsaidfe78f7236fs7vbsds") }
  # end
      
  # def test_game_creation_fails_on_topic_with_no_main_image
  #   assert_raises(ArgumentError) { BoardGame.new("Dungeons and Dragons") }
  # end

  # def test_game_can_be_initiated
  #   TOPICS.each do |t|
  #     assert BoardGame.new(t), msg: "Topic was '#{t}'"
  #   end
  # end

  # def test_game_has_name
  #   TOPICS.each do |t|
  #     game = BoardGame.new(t)
  #     assert (game.name.is_a?(String) && !game.name.empty?), msg: "Topic was '#{t}'"
  #   end
  # end

  # def test_game_has_description
  #   TOPICS.each do |t|
  #     game = BoardGame.new(t)
  #     assert (game.description.is_a?(String) && !game.description.empty?), msg: "Topic was '#{t}'"
  #   end
  # end

  # # Assembly Instruction Tests
  # def test_game_assembly_instructions_pdf_can_be_generated
  #   TOPICS.each do |t|
  #     game = BoardGame.new(t)
  #     assert (!game.assembly_instructions.nil? && game.assembly_instructions.pdf.is_a?(Prawn::Document)), msg: "Topic was '#{t}'"
  #   end
  # end

  # # Chance Cards Tests
  # def test_game_chance_cards_can_be_generated
  #   TOPICS.each do |t|
  #     assert BoardGame.new(t).chance_cards, msg: "Topic was '#{t}'"
  #   end
  # end

  # def test_game_chance_cards_arent_empty
  #   TOPICS.each do |t|
  #     refute BoardGame.new(t).chance_cards.all.empty?, msg: "Topic was '#{t}'"
  #   end
  # end

  # def test_game_chance_cards_have_no_blank_events
  #   TOPICS.each do |t|
  #     assert BoardGame.new(t).chance_cards.all.map { |c|
  #       c.event.is_a?(String) && !c.event.empty?
  #     }.all?, msg: "Topic was '#{t}'"
  #   end
  # end

  # def test_game_chance_cards_have_no_blank_consequences
  #   TOPICS.each do |t|
  #     assert BoardGame.new(t).chance_cards.all.map { |c|
  #       c.consequence.is_a?(String) && !c.consequence.empty?
  #     }.all?, msg: "Topic was '#{t}'"
  #   end
  # end

  # def test_game_chance_cards_have_valid_sentiment_scores
  #   TOPICS.each do |t|
  #     assert BoardGame.new(t).chance_cards.all.map { |c|
  #       (-1.0..1.0).include?(c.sentiment)
  #     }.all?, msg: "Topic was '#{t}'"
  #   end
  # end

  # def test_game_chance_cards_pdf_can_be_generated
  #   TOPICS.each do |t|
  #     game = BoardGame.new(t)
  #     assert (!game.chance_cards.nil? && game.chance_cards.pdf.is_a?(Prawn::Document)), msg: "Topic was '#{t}'"
  #   end
  # end

  # # Game Board Tests
  # def test_game_board_pdf_can_be_generated
  #   TOPICS.each do |t|
  #     game = BoardGame.new(t)
  #     assert (!game.game_board.nil? && game.game_board.pdf.is_a?(Prawn::Document)), msg: "Topic was '#{t}'"
  #   end
  # end

  # # Game Box Tests
  # def test_game_box_has_image_url
  #   TOPICS.each do |t|
  #     assert BoardGame.new(t).game_box.image_url, msg: "Topic was '#{t}'"
  #   end
  # end

  # def test_game_box_can_be_generated
  #   TOPICS.each do |t|
  #     game = BoardGame.new(t)
  #     assert (!game.game_box.nil? && game.game_box.pdf.is_a?(Prawn::Document)), msg: "Topic was '#{t}'"
  #   end
  # end

  # # Game Instructions Tests
  # def test_game_instructions_pdf_can_be_generated
  #   TOPICS.each do |t|
  #     game = BoardGame.new(t)
  #     assert (!game.game_instructions.nil? && game.game_instructions.pdf.is_a?(Prawn::Document)), msg: "Topic was '#{t}'"
  #   end
  # end

  # # Game Money Tests
  # def test_game_money_pdf_can_be_generated
  #   TOPICS.each do |t|
  #     game = BoardGame.new(t)
  #     assert (!game.game_money.nil? && game.game_money.pdf.is_a?(Prawn::Document)), msg: "Topic was '#{t}'"
  #   end
  # end

  # # Game Pieces Tests
  # def test_game_has_correct_number_of_game_pieces
  #   TOPICS.each do |t|
  #     assert_equal BoardGame.new(t).game_pieces.all.count, GamePieces::NUMBER_OF_PIECES, msg: "Topic was '#{t}'"
  #   end
  # end

  # def test_game_pieces_all_have_names
  #   TOPICS.each do |t|
  #     assert BoardGame.new(t).game_pieces.all.map { |gp|
  #       gp.name.is_a?(String) && !gp.name.empty?
  #     }.all?, msg: "Topic was '#{t}'"
  #   end
  # end

  # def test_game_pieces_all_have_image_urls
  #   TOPICS.each do |t|
  #     assert BoardGame.new(t).game_pieces.all.map { |gp|
  #       gp.image_url.is_a?(String) && !gp.image_url.empty?
  #     }.all?, msg: "Topic was '#{t}'"
  #   end
  # end

  # # Question Cards Tests
  # def test_game_question_cards_can_be_generated
  #   TOPICS.each do |t|
  #     assert BoardGame.new(t).question_cards, msg: "Topic was '#{t}'"
  #   end
  # end

  # def test_game_question_cards_have_questions_and_answers
  #   TOPICS.each do |t|
  #     refute BoardGame.new(t).question_cards.all.empty?, msg: "Topic was '#{t}'"
  #   end
  # end

  # def test_game_question_cards_have_no_blank_questions
  #   TOPICS.each do |t|
  #     assert BoardGame.new(t).question_cards.all.map { |q|
  #       q.question.is_a?(String) && !q.question.empty?
  #     }.all?, msg: "Topic was '#{t}'"
  #   end
  # end

  # def test_game_question_cards_have_no_blank_choices
  #   TOPICS.each do |t|
  #     assert BoardGame.new(t).question_cards.all.map { |q|
  #       q.choices.map { |c|
  #         c.is_a?(String) && !c.empty?
  #       }
  #     }.flatten.all?, msg: "Topic was '#{t}'"
  #   end  
  # end

  # def test_game_question_cards_have_no_blank_answers
  #   TOPICS.each do |t|
  #     assert BoardGame.new(t).question_cards.all.map { |q|
  #       q.answer.is_a?(String) && !q.answer.empty?
  #     }.all?, msg: "Topic was '#{t}'"
  #   end
  # end  

  def test_game_question_cards_pdf_can_be_generated
    TOPICS.each do |t|
      game = BoardGame.new(t)
      assert (!game.question_cards.nil? && game.question_cards.pdf.is_a?(Prawn::Document)), msg: "Topic was '#{t}'"
    end
  end

  # Game PDF Tests
  def test_game_pdf_can_be_generated
    TOPICS.each do |t|
      game = BoardGame.new(t)
      assert (game.pdf.is_a?(Prawn::Document)), msg: "Topic was '#{t}'"
    end
  end

end