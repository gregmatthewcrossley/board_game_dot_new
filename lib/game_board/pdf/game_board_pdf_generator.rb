module GameBoardPdfGenerator

  require_rel '../../pdf/pdf.rb'
  include Pdf

  PDF_ATTRIBUTES = {
    page_size:   'LETTER', 
    page_layout: :landscape
  }


  private


  def build_pdf(prawn_document = Prawn::Document.new(PDF_ATTRIBUTES))
    super(prawn_document).tap do |p| 
      p.font('Courier', size: 8) do
        p.text as_text
      end
    end
  end

end