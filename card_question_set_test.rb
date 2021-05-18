# card_question_set_test.rb
require 'minitest/autorun'
require_relative 'card_question_set'

class CardQuestionSetTest < Minitest::Test

  parallelize_me!

  TOPICS = [
    "Chorioactis",
    "Francis Walsingham",
    "Albert Einstein"
  ]

  def test_requires_a_topic
    assert_raises(ArgumentError) { CardQuestionSet.new }
  end

  def test_set_can_be_initiated
    TOPICS.each do |t|
      assert CardQuestionSet.new(t), msg: "Topic was '#{t}'"
    end
  end

  def test_set_can_be_generated
    TOPICS.each do |t|
      assert CardQuestionSet.new(t).generate, msg: "Topic was '#{t}'"
    end
  end

  def test_set_has_questions_and_answers
    TOPICS.each do |t|
      assert (CardQuestionSet.new(t).generate(count: 5).questions_and_answers.count == 5), msg: "Topic was '#{t}'"
    end
  end

  def test_set_has_no_blank_questions
    TOPICS.each do |t|
      assert CardQuestionSet.new(t).generate(count: 100).questions_and_answers.map { |q|
        q[:question].is_a?(String) && !q[:question].empty?
      }.all?, msg: "Topic was '#{t}'"
    end
  end

  def test_set_has_no_blank_answers
    TOPICS.each do |t|
      assert CardQuestionSet.new(t).generate(count: 100).questions_and_answers.map { |q|
        q[:choices].map { |c|
          c.is_a?(String) && !c.empty?
        }
      }.flatten.all?, msg: "Topic was '#{t}'"
    end  
  end

end