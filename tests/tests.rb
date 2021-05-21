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
  #   "Dungeons and Dragons"
  # ]

  def test_board_game_creation_requires_a_topic
    assert_raises(ArgumentError) { BoardGame.new }
  end

  def test_board_game_creation_fails_on_obscure_topic
    assert_raises(ArgumentError) { BoardGame.new("buiwfubsaidfe78f7236fs7vbsds") }
  end

  def test_board_game_can_be_initiated
    TOPICS.each do |t|
      assert BoardGame.new(t), msg: "Topic was '#{t}'"
    end
  end

  def test_board_game_has_name
    TOPICS.each do |t|
      game = BoardGame.new(t)
      assert (game.name.is_a?(String) && !game.name.empty?), msg: "Topic was '#{t}'"
    end
  end

  def test_board_game_has_description
    TOPICS.each do |t|
      game = BoardGame.new(t)
      assert (game.description.is_a?(String) && !game.description.empty?), msg: "Topic was '#{t}'"
    end
  end

  def test_board_game_question_cards_can_be_generated
    TOPICS.each do |t|
      assert BoardGame.new(t).question_cards, msg: "Topic was '#{t}'"
    end
  end

  def test_board_game_question_cards_have_questions_and_answers
    TOPICS.each do |t|
      refute BoardGame.new(t).question_cards.empty?, msg: "Topic was '#{t}'"
    end
  end

  def test_board_game_question_cards_have_no_blank_questions
    TOPICS.each do |t|
      assert BoardGame.new(t).question_cards.map { |q|
        q.question.is_a?(String) && !q.question.empty?
      }.all?, msg: "Topic was '#{t}'"
    end
  end

  def test_board_game_question_cards_have_no_blank_choices
    TOPICS.each do |t|
      assert BoardGame.new(t).question_cards.map { |q|
        q.choices.map { |c|
          c.is_a?(String) && !c.empty?
        }
      }.flatten.all?, msg: "Topic was '#{t}'"
    end  
  end

  def test_board_game_question_cards_have_no_blank_answers
    TOPICS.each do |t|
      assert BoardGame.new(t).question_cards.map { |q|
        q.answer.is_a?(String) && !q.answer.empty?
      }.all?, msg: "Topic was '#{t}'"
    end
  end

  def test_board_game_chance_cards_can_be_generated
    TOPICS.each do |t|
      assert BoardGame.new(t).chance_cards, msg: "Topic was '#{t}'"
    end
  end

  def test_board_game_chance_cards_arent_empty
    TOPICS.each do |t|
      refute BoardGame.new(t).chance_cards.empty?, msg: "Topic was '#{t}'"
    end
  end

  def test_board_game_chance_cards_have_no_blank_events
    TOPICS.each do |t|
      assert BoardGame.new(t).chance_cards.map { |c|
        c.event.is_a?(String) && !c.event.empty?
      }.all?, msg: "Topic was '#{t}'"
    end
  end

  def test_board_game_chance_cards_have_no_blank_consequences
    TOPICS.each do |t|
      assert BoardGame.new(t).chance_cards.map { |c|
        c.consequence.is_a?(String) && !c.consequence.empty?
      }.all?, msg: "Topic was '#{t}'"
    end
  end

  def test_board_game_chance_cards_have_valid_sentiment_scores
    TOPICS.each do |t|
      assert BoardGame.new(t).chance_cards.map { |c|
        (-1.0..1.0).include?(c.sentiment)
      }.all?, msg: "Topic was '#{t}'"
    end
  end

end