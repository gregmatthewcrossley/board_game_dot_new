module QuestionCardsPdfGenerator

  require_rel '../../pdf/pdf.rb'
  include Pdf


  private


  def build_pdf(prawn_document)
    super.tap do |p|
      @question_cards.each do |question_card|
        # make a new page for each chance card
        p.text "Question Card", size: 10
        p.text question_card.question, size: 8
        question_card.choices.each_with_index do |choice, i|
          p.text "  #{i + 1}. #{choice}", size: 6
        end
        p.text "answer: #{question_card.answer}", size: 4
        p.start_new_page
      end
    end
  end

end