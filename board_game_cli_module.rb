module BoardGameCli
  def cli # class method

    puts
    print "Enter your board game topic: "

    begin  
      input_topic = gets.chomp
      board_game = BoardGame.new(input_topic)
    rescue ArgumentError => e
      puts "Sorry, can't create a board game for '" + input_topic + "' because " + e.message
      puts
      exit
    end

    puts 
    puts board_game.name.gsub(/./, '-')
    puts board_game.name
    puts board_game.name.gsub(/./, '-')
    puts board_game.description
    puts
    puts
    puts "Generating question cards ..."

    board_game.question_cards.each_with_index do |qc, i|
      puts qc.question
      ("a".."z").to_a[0..(qc.choices.count - 1)].each_with_index do |letter, i|
        puts "  (#{letter}) " + qc.choices[i]
      end
      puts 
      puts "   answer: " + qc.answer
      puts
      puts

    end; :done

  end # end of cli class method
end # end of module