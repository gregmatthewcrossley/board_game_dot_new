module GameBoxPdfGenerator

  require_rel '../../pdf/pdf.rb'
  include Pdf

  PDF_ATTRIBUTES = {
    page_size:   'LETTER', 
    page_layout: :landscape
  }

  private


  def build_pdf(prawn_document = Prawn::Document.new(PDF_ATTRIBUTES))
    # first, call build_pdf() from the Pdf module (for general PDF setup and content)
    # then run the code below (to add component-specific content)
    super(prawn_document).tap do |p| 
      p.image @main_image.path, width: 150
      p.text @game_name, size: 24
      p.text @game_description, size: 16
    end
  end

end