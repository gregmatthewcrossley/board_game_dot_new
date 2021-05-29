module GamePdfGenerator

  def generate_pdf
    build_pdf.tap do |p|
      # add an 'open' method (for opening the PDF in Preview on MacOS)
      p.define_singleton_method(:open) do
        path_and_filename = "../.temp_pdf/game.pdf"
        combined_pdf.save path_and_filename
        system "open #{path_and_filename}"
      end
    end
  end

  def pdf
    @pdf ||= generate_pdf
  end


  private


  def build_pdf
    combined_pdf = CombinePDF.new
    BoardGame::GAME_COMPONENTS.each do |component|
      combined_pdf << CombinePDF.parse(send(component).pdf.render)
    end
    return combined_pdf
  end

end