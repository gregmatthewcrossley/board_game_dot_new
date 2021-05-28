module ChanceCardsPdfGenerator

  def generate_pdf
    build_pdf.tap do |p|
      p.define_singleton_method(:open) do
        # add an 'open' method (for opening the PDF in Preview on MacOS)
        path_and_filename = "../.temp_pdf/chance_cards.pdf"
        render_file(path_and_filename)
        system "open #{path_and_filename}"
      end
    end
  end

  def pdf
    @pdf ||= generate_pdf
  end


  private


  def build_pdf
    Prawn::Document.new do
      text "Placeholder Chance Cards PDF"
    end
  end

end