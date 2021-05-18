# to run in terminal: ruby cli_interface.rb

require_relative 'card_question_set'
puts
puts "Card Questions"
puts "---------------"
print "Enter your topic: "

begin  
  input_topic = gets.chomp
  question_set = CardQuestionSet.new(input_topic)
rescue ArgumentError => e
  puts "Sorry, can't create questions for '" + input_topic + "' because " + e.message
  puts
  exit
end

puts
puts "Found Wikipedia page entitled '" + question_set.wikipedia_page_title + "'. Generating questions..."

question_set.generate

question_set.questions_and_answers.each_with_index do |q_and_a, i|
  # TO DO: generalize this (any number of questions)
  puts "(#{(i + 1).to_s}) #{q_and_a[:question]}"
  ("a".."z").to_a[0..(q_and_a[:choices].count - 1)].each_with_index do |letter, i|
    puts "  (#{letter}) " + q_and_a[:choices][i]
  end
  puts 
  puts "   answer: " + q_and_a[:answer]
  puts
  puts
end