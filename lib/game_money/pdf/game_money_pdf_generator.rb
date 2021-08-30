module GameMoneyPdfGenerator

  require_rel '../../pdf/pdf.rb'
  include Pdf


  private


  def build_pdf(prawn_document)
    super.tap do |p|
      quantity.times do
        p.text "Money for #{@topic}", size: 36
        p.start_new_page
      end
    end
  end

end