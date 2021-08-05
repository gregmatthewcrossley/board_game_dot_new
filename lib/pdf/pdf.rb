module Pdf # a parent class that manages the retrieval, storage and preview generation for PDFs

  def external_pdf_filename
    "Component#{self.class.name}.pdf"
  end

  def external_pdf_preview_filename(page_number)
    raise ArgumentError, 'page_number must be a positive Integer' unless page_number.is_a?(Integer) && page_number > 0
    "Component#{self.class.name}_preview_page#{page_number.to_s.rjust(3, "0")}.png" # ensures all generated preview files are PNGs
  end

  def pdf
    @pdf ||= retrieve_pdf || generate_pdf
  end

  def pdf_preview(page = 1)
    @pdf_preview ||= retrieve_pdf_preview(page) || generate_pdf_preview(page)
  end

  def retrieve_pdf
    ExternalPersistentStorage.retrieve_file(@topic, external_pdf_filename, public_pdf: self.class == BoardGame)
  end

  def retrieve_pdf_preview(page = 1)
    ExternalPersistentStorage.retrieve_file(@topic, external_pdf_preview_filename(page))
  end

  def generate_pdf(prawn_document = Prawn::Document.new)
    raise ArgumentError, 'must pass a Prawn::Document' unless prawn_document.is_a?(Prawn::Document)
    Tempfile.new.tap do |f|
      begin
        # build the PDF and render it to this tempfile
        f.write(build_pdf(prawn_document).render)
        # attempt to store the PDF Tempfile for next time
        ExternalPersistentStorage.save_file(
          @topic,
          external_pdf_filename,
          f,
          public_pdf: self.class == BoardGame
        )
        # add a singleton method to this tempfile to allow it to be easily opened locally
        add_local_open_method
      ensure
        f.close
      end
    end # return a closed tempfile
  end

  def generate_pdf_preview(page = 1)
    raise ArgumentError, 'page must be a positive Integer' unless page.is_a?(Integer) && page > 1
    # create a tempfile for the preview image
    Tempfile.new(
      [
        external_pdf_preview_filename(page).split('.').first,
        "." + external_pdf_preview_filename(page).split('.').last
      ],
      binmode: true
    ) do |f|
      begin
        # open the given page of this PDF using MiniMagic::Image
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
          convert << f.path
        end
        f.open # refresh the preview image tempfile TO-DO: is this :open step neccesary? why does it 'refresh' and what does that mean? is this a quirk of imagemagic?
        # save this preview image tempfile for next time
        ExternalPersistentStorage.save_pdf_preview(
          @topic,
          external_pdf_preview_filename(page),
          f
        )
        # add a singleton method to this tempfile to allow it to be easily opened locally
        add_local_open_method
      ensure
        f.close 
      end
    end
  end

  def build_pdf(prawn_document)
    raise ArgumentError, 'must pass a Prawn::Document' unless prawn_document.is_a?(Prawn::Document)
    prawn_document.tap do |p|
      # anything you want at the start of all components, add here!
    end
  end


  # Private methods

  def add_local_open_method
    define_singleton_method(
      :open,
      Proc.new do
        render_file(path_and_pdf_filename)
        self.open
        self.rewind
        system "open #{self.path}"
      end
    )
  end
  # # private_class_method :add_local_open_method

end