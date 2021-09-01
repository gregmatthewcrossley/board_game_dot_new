module Pdf # a parent class that manages the retrieval, storage and preview generation for PDFs

  require_rel './local_open.rb'
  prepend LocalOpen

  # here, we wrap the :initialize method from each component to allow us to skip
  # the very time consuming step of retrieving and/or processing the component data
  # if a finalized PDF already exists (and that's all we want, ie for previewing).
  def initialize(topic, use_existing_pdf: false)
    # validate the topic argument
    raise ArgumentError, "must pass a topic (a non-empty String)" unless topic.is_a?(String) && !topic.empty?
    @topic = topic
    if use_existing_pdf
      unless retrieve_pdf # unless a PDF exists already ...
        warn "warning: the use_existing_pdf argument was set to true when this component was initialized, but no PDF exists yet. This argument will be ignored"
        super(topic)
      end
    else
      # call the regular :initialize method (taking the time to retrieve and/or processing the component data)
      super(topic)
    end
  end

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
    ExternalPersistentStorage.retrieve_file(@topic, external_pdf_filename, public_pdf: self.class == BoardGame) # will be public only if it is the main BoardGame PDF
  end

  def retrieve_pdf_preview(page = 1)
    ExternalPersistentStorage.retrieve_file(@topic, external_pdf_preview_filename(page))
  end

  def generate_pdf(prawn_document = Prawn::Document.new(:page_size => [3 * 72, 3 * 72]))
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
    raise ArgumentError, 'page must be a positive Integer' unless page.is_a?(Integer) && page > 0
    # create a tempfile for the preview image
    Tempfile.new(
      [
        external_pdf_preview_filename(page).split('.').first,
        "." + external_pdf_preview_filename(page).split('.').last
      ],
      binmode: true
    ).tap do |f|
      begin
        # open the given page of this PDF using MiniMagic::Image
        pdf_page = MiniMagick::Image
          .new(pdf.path)
          .pages[page - 1] # array index starts at 0, but page numbers start at 1
        raise ArgumentError, "#{self.class.name}'s PDF for #{@topic} does not have a page #{page}" unless pdf_page
        # use MiniMagick::Tool::Convert to convert the pdf_page into an image
        # and save it to the preview image tempfile created above
        MiniMagick::Tool::Convert.new do |convert|
          convert.background 'white'
          convert.flatten
          convert.density 150
          convert.quality 95
          convert << pdf_page.path
          convert << f.path
        end
        f.open # refresh the preview image tempfile TO-DO: is this :open step neccesary? why does it 'refresh' and what does that mean? is this a quirk of imagemagic?
        # save this preview image tempfile for next time
        ExternalPersistentStorage.save_file(
          @topic,
          external_pdf_preview_filename(page),
          f
        )
        # add a singleton method to this tempfile to allow it to be easily opened locally
        add_local_open_method
      ensure
        f.close 
      end
    end # end Tempfile block
  end

  def build_pdf(prawn_document)
    raise ArgumentError, 'must pass a Prawn::Document' unless prawn_document.is_a?(Prawn::Document)
    prawn_document.tap do |p|
      # anything you want at the start of all components, add here!
    end
  end

end