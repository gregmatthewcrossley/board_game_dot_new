module GamePdfGenerator

  require_rel './local_open.rb'
  prepend LocalOpen

  # here, we wrap the :initialize method from BoardGame to allow us to skip
  # the very time consuming step of retrieving and/or processing each game component's data
  # if a finalized PDF already exists (and that's all we want, ie for combinging into the final PDF).
  def initialize(topic, use_existing_pdf: false)
    # validate the topic argument
    raise ArgumentError, "must pass a topic (a non-empty String)" unless topic.is_a?(String) && !topic.empty?
    @topic = topic
    if use_existing_pdf
      unless retrieve_pdf # unless a PDF exists already ...
        warn "warning: the use_existing_pdf argument was set to true when BoadGame was initialized, but no final PDF exists yet."
      end
    else
      # call the regular :initialize method (taking the time to retrieve and/or processing each component's data)
      super(topic)
    end
  end

  def pdf
    @pdf ||= retrieve_pdf || generate_pdf
  end

  def public_pdf_url
    url_string_lambda = -> { return ExternalPersistentStorage.retrieve_public_pdf_url(@topic, external_pdf_filename) }
    if url_string = url_string_lambda.call
      return url_string
    else
      pdf # we call this method first to ensure that either a) the PDF exists in storage already, or b) the PDF is generated and stored now
      return url_string_lambda.call
    end
  end


  private


  def external_pdf_filename
    "#{@topic}.pdf"
  end

  def retrieve_pdf
    ExternalPersistentStorage.retrieve_file(@topic, external_pdf_filename, public_pdf: true)
  end

  def generate_pdf
    Tempfile.new([@topic, ".pdf"]).tap do |f|
      begin
        # build the PDF and render it to this tempfile
        pdf = CombinePDF.new
        BoardGame::GAME_COMPONENT_NAMES_AND_CLASSES.each do |component_name, component_class|
          pdf << CombinePDF.load(component_class.new(@topic, use_existing_pdf: true).pdf.path)
        end
        pdf.save(f.path)
        # attempt to store the PDF Tempfile for next time
        ExternalPersistentStorage.save_file(
          @topic,
          external_pdf_filename,
          f,
          public_pdf: true
        )
        # # add a singleton method to this tempfile to allow it to be easily opened locally
        # add_local_open_method
      ensure
        f.close
      end
    end # return a closed tempfile
  end

end
