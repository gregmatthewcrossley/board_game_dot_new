# card_question_set_test.rb
require 'minitest/autorun'
require_relative 'card_question_set'

class CardQuestionSetTest < Minitest::Test

  def test_requires_a_topic
    assert_raises(ArgumentError) { CardQuestionSet.new }
  end

  def test_set_can_be_initiated
    assert CardQuestionSet.new("Rob Ford")
  end

  def test_set_can_be_generated
    assert CardQuestionSet.new("Rob Ford").generate
  end

  def test_set_has_questions_and_answers
    assert CardQuestionSet.new("Rob Ford").generate(count: 100).questions_and_answers.count == 100
  end

  def test_set_has_no_blank_questions
    assert CardQuestionSet.new("Rob Ford").generate(count: 100).questions_and_answers.map { |q|
      q[:question].is_a?(String) && !q[:question].empty?
    }.all?
  end

  def test_set_has_no_blank_answers
    assert CardQuestionSet.new("Rob Ford").generate(count: 100).questions_and_answers.map { |q|
      q[:choices].map { |c|
        c.is_a?(String) && !c.empty?
      }
    }.flatten.all?  
  end

end