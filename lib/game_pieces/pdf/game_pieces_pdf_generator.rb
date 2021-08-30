module GamePiecesPdfGenerator

  require_rel '../../pdf/pdf.rb'
  include Pdf


  private


  def build_pdf(prawn_document)
    super.tap do |p|
      @game_pieces.values.each do |game_piece_name|
        # make a new page for each game piece
        # p.image ExternalImageSource::Any.new(game_piece_name).tempfile.path, width: 150
        p.text "Game Piece: #{game_piece_name}", size: 24
        p.start_new_page
      end
    end
  end

end