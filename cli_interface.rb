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

question_set.questions_and_answers.each do |q_and_a|
  # TO DO: generalize this (any number of questions)
  puts q_and_a[:question]
  puts "  (a) " + q_and_a[:choices][0]
  puts "  (b) " + q_and_a[:choices][1]
  puts "  (c) " + q_and_a[:choices][2]
  puts "  (d) " + q_and_a[:choices][3]
  puts 
  puts "   answer: " + q_and_a[:answer]
  puts
  puts
end