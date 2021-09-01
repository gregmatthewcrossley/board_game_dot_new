module AssemblyInstructionsPdfGenerator

  require_rel '../../pdf/pdf.rb'
  include Pdf

  PDF_ATTRIBUTES = {
    page_size:   'LETTER', 
    page_layout: :portrait
  }


  private


  def build_pdf(prawn_document = Prawn::Document.new(PDF_ATTRIBUTES))
    # first, call build_pdf() from the Pdf module (for general PDF setup and content)
    # then run the code below (to add component-specific content)
    super(prawn_document).tap do |p| 
      p.text "Assembly Instructions", size: 16
      p.text "Cut everything out and tape it together.", size: 10
    end
  end

end
