# to run in terminal: ruby cli_interface.rb

require_relative 'twenty_one_dots'
puts
puts "Twenty One Dots"
puts "---------------"
print "Enter your keyword: "

begin  
  input_keyword = gets.chomp
  instance = TwentyOneDots.new(input_keyword)
rescue ArgumentError => e
  puts "Sorry, can't create a game with '" + input_keyword + "' because " + e.message
  puts
  exit
end

puts
puts "Found Wikipedia page entitled '" + instance.wikipedia_page_title + "':"
puts instance.entities
puts