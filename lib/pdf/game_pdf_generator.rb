module GamePdfGenerator

  require_rel './pdf.rb'
  include Pdf


  private


  def build_pdf(prawn_document)
    generate
    super.tap do |p|
      BoardGame::GAME_COMPONENTS.each_with_index do |component, i|
        send(component).generate_pdf(p)
        # start a new page for the next component, unless this was the last component
        p.start_new_page unless i == (BoardGame::GAME_COMPONENTS.count - 1)
      end
    end
  end

end
