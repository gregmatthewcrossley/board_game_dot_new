module ChanceCardsPdfGenerator

  require_rel '../../pdf/pdf.rb'
  include Pdf


  private


  def build_pdf(prawn_document)
    super.tap do |p|
      @chance_cards.each do |chance_card|
        # make a new page for each chance card
        p.text "Chance Card", size: 24
        p.text chance_card.event, size: 18
        p.text chance_card.consequence, size: 14
        p.start_new_page
      end
    end
  end

end