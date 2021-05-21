require_relative '../lib/board_game'

puts
print "Enter your board game topic: "

# Initialize the board game
begin  
  input_topic = gets.chomp
  board_game = BoardGame.new(input_topic)
rescue ArgumentError => e
  puts "Sorry, can't create a board game for '" + input_topic + "' because " + e.message
  puts
  exit
end

# Show the board game's title
puts 
puts board_game.name.gsub(/./, '-')
puts board_game.name
puts board_game.name.gsub(/./, '-')
puts board_game.description
puts

# Show the game board
puts
board_game.game_board.print

# # Generate and show image URLs
# puts
# puts "Generating image URLs ..."
# puts
# puts "Main image: #{board_game.game_box.image_url}"
# puts
# puts "Game Pieces: "
# board_game.game_pieces.each do |p|
#   puts p
# end

# # Generate and show question cards
# puts
# puts "Generating question cards ..."
# board_game.question_cards.each_with_index do |qc, i|
#   puts qc.question
#   ("a".."z").to_a[0..(qc.choices.count - 1)].each_with_index do |letter, i|
#     puts "  (#{letter}) " + qc.choices[i]
#   end
#   puts 
#   puts "   answer: " + qc.answer
#   puts
#   puts

# end; exit;
