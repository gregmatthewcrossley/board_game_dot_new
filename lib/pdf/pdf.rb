module Pdf # a parent class that manages the retrieval, storage and preview generation for PDFs

  def pdf
    @pdf ||= retrieve_pdf || generate_pdf
  end

  def pdf_preview(page = 1)
    @pdf_preview ||= retrieve_pdf_preview(page) || generate_pdf_preview(page)
  end

  def retrieve_pdf
    ExternalPersistentStorage.retrieve_pdf(@topic, self.class)
  end

  def retrieve_pdf_preview(page = 1)
    ExternalPersistentStorage.retrieve_pdf_preview(@topic, self.class, page)
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

  def generate_pdf_preview(page = 1)
    begin
      # create a tempfile for the preview image
      pdf_preview_image_tempfile = Tempfile.new(["page-#{page}", ".png"], binmode: true)
      # open the PDF using MiniMagic::Image
      pdf_page = MiniMagick::Image
        .new(pdf.path)
        .pages[page]
      # use MiniMagick::Tool::Convert to convert the pdf_page into an image
      # and save it to the preview image tempfile created above
      MiniMagick::Tool::Convert.new do |convert|
        convert.background 'white'
        convert.flatten
        convert.density 300
        convert.quality 95
        convert << pdf_page.path
        convert << pdf_preview_image_tempfile.path
      end
      pdf_preview_image_tempfile.open # refresh the preview image tempfile
    ensure
      pdf.close 
    end
    # save this preview image tempfile for next time
    ExternalPersistentStorage.save_pdf_preview(
      @topic,
      pdf_preview_image_tempfile,
      self.class,
      page
    )
    return pdf_preview_image_tempfile
  end

  def build_pdf(prawn_document)
    raise ArgumentError, 'must pass a Prawn::Document' unless prawn_document.is_a?(Prawn::Document)
    prawn_document.tap do |p|
      # anything you want at the start of all components, add here!
    end
  end

end