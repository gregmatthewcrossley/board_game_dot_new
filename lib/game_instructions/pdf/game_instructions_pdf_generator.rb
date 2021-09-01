module GameInstructionsPdfGenerator

  require_rel '../../pdf/pdf.rb'
  include Pdf

  PDF_ATTRIBUTES = {
    page_size:   'LETTER', 
    page_layout: :portrait
  }

  private


  def build_pdf(prawn_document)
    super.tap do |p|
      p.text "Placeholder #{self.class.name} PDF for #{@topic}"
    end
  end

  def build_pdf(prawn_document = Prawn::Document.new(PDF_ATTRIBUTES))
    # first, call build_pdf() from the Pdf module (for general PDF setup and content)
    # then run the code below (to add component-specific content)
    super(prawn_document).tap do |p| 
      p.text "How To Play '#{@game_name}'", size: 16
      p.text "Play it like snakes and ladders / monopoly.", size: 10
    end
  end

end