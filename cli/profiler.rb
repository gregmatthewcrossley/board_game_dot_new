# sudo rbspy record ruby profiler.rb

ENV['GOOGLE_APPLICATION_CREDENTIALS']="../google_application_credentials.json" 

require_relative '../lib/board_game'

# infinite loop - gives you a chance to find the ruby PID and scan it
# using `sudo rbspy record --pid $PID`
puts "Beginning infinite loop. To profile, run:\nsudo rbspy record --rate 10 --pid #{Process.pid}"
loop do
  BoardGame.new("Rob Ford").tap do |g|
    g.game_board
    g.game_box
    g.game_pieces
    g.question_cards
    g.chance_cards
  end
end