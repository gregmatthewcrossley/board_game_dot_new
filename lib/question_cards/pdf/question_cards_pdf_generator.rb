module QuestionCardsPdfGenerator

  require_rel '../../pdf/pdf.rb'
  include Pdf


  private


  def build_pdf(prawn_document)
    super.tap do |p|
      p.text "Placeholder #{self.class.name} PDF for #{@topic}"
    end
  end

end