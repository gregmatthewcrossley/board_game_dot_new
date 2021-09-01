module GamePiecesPdfGenerator

  require_rel '../../pdf/pdf.rb'
  include Pdf

  PDF_ATTRIBUTES = {
    page_size: [3 * 72, 5 * 72]
  }

  private


  def build_pdf(prawn_document = Prawn::Document.new(PDF_ATTRIBUTES))
    super(prawn_document).tap do |p| 
      @game_pieces.values.each_with_index do |game_piece_name, i|
        # make a new page for each game piece
        p.image ExternalImageSource::Any.new(game_piece_name).tempfile.path, width: 100
        p.text "Game Piece: #{game_piece_name}", size: 12
        p.start_new_page unless (i+1) == @game_pieces.count
      end
    end
  end

end