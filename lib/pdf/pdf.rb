module Pdf

  def pdf
    @pdf ||= retrieve_pdf || generate_pdf
  end

  def pdf_preview
    @pdf_preview ||= retrieve_pdf_preview || generate_pdf_preview
  end

  def retrieve_pdf
    ExternalPersistentStorage.retrieve_pdf(@topic, self.class)
  end

  def retrieve_pdf_preview
    ExternalPersistentStorage.retrieve_pdf_preview(@topic, self.class)
  end

  def generate_pdf(prawn_document = Prawn::Document.new)
    raise ArgumentError, 'must pass a Prawn::Document' unless prawn_document.is_a?(Prawn::Document)
    # pdf_file_name = "#{self.class.name.gsub(/(.)([A-Z])/,'\1_\2').downcase}.pdf"
    # path_and_pdf_filename = "../tmp/#{pdf_file_name}"
    # build_pdf(prawn_document)
    #   .tap do |p| # add an 'open' method to open the PDF locally
    #     _open = Proc.new do
    #       render_file(path_and_pdf_filename)
    #       system "open #{path_and_pdf_filename}"
    #     end
    #     p.define_singleton_method(:open, _open)
    #   end
    Tempfile.new.tap do |tf|
      begin
        tf.write(build_pdf(prawn_document).render)
        tf.rewind
        # attempt to store the image Tempfile for next time
        ExternalPersistentStorage.save_pdf(
          @topic,
          tf,
          self.class
        )
      ensure
        tf.close
      end
    end # return a closed tempfile
  end

  def generate_pdf_preview
    begin
      pages = {}
      MiniMagick::Image.new(pdf.path)
        .pages.each_with_index do |page, index|
          page_image = Tempfile.new(["page-#{index}", ".png"], binmode: true)
          MiniMagick::Tool::Convert.new do |convert|
            convert.background 'white'
            convert.flatten
            convert.density 300
            convert.quality 95
            convert << page.path
            convert << page_image.path
          end
          page_image.open # refresh updated file
          pages[1] = page_image
        end
    ensure
      pdf.close
    end
    pages.each do |page_number, page|
      ExternalPersistentStorage.save_pdf_preview(
        @topic,
        page,
        self.class
      )
    end
    return pages[1]
  end

  def build_pdf(prawn_document)
    raise ArgumentError, 'must pass a Prawn::Document' unless prawn_document.is_a?(Prawn::Document)
    prawn_document.tap do |p|
      # anything you want at the start of all components, add here!
    end
  end

end