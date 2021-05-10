# to run in terminal: ruby cli_interface.rb

require_relative 'twenty_one_dots'
puts
puts "Twenty One Dots"
puts "---------------"
print "Enter your keyword: "

begin  
  instance = TwentyOneDots.new(gets.chomp)
rescue ArgumentError => e
  puts "Sorry, can't create a game with this keyword because " + e.message
  puts
  exit
end

puts
puts "You entered '" + instance.keyword + "'"
puts instance.wikipedia_page_text
puts