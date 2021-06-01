  require 'benchmark'

  require_relative '../lib/board_game'

  board_game = BoardGame.new("Rob Ford")
  board_game.pdf.open

