module ChanceCardsPdfGenerator

  require_rel '../../pdf/pdf.rb'
  include Pdf

  PDF_ATTRIBUTES = {
    page_size: [5 * 72, 3 * 72] 
  }


  private


  def build_pdf(prawn_document = Prawn::Document.new(PDF_ATTRIBUTES))
    super(prawn_document).tap do |p| 
      @chance_cards.each do |chance_card|
        # make a new page for each chance card
        p.text "Chance Card", size: 10
        p.text chance_card.event, size: 8
        p.text chance_card.consequence, size: 6
        p.start_new_page unless (i+1) == @chance_cards.count
      end
    end
  end

end