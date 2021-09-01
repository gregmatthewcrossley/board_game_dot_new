module GameMoneyPdfGenerator

  require_rel '../../pdf/pdf.rb'
  include Pdf

  PDF_ATTRIBUTES = {
    page_size: [5 * 72, 3 * 72]
  }

  private


  def build_pdf(prawn_document = Prawn::Document.new(PDF_ATTRIBUTES))
    super(prawn_document).tap do |p| 
      quantity.times do |i|
        p.text "$1", size: 24
        p.text "One Dollar", size: 24
        p.start_new_page unless (i+1) == quantity
      end
    end
  end

end