module GoogleCloudStorage

  require 'stringio'

  # Google Cloud Storage bucket names and paths
  BUCKET_NAME = 'board-game-dot-new'
  BUCKET_PATH_FOR = {
    :source_text     => Proc.new { |title|                         ".game_data/#{title.downcase}/source_text.json"                             },
    :image           => Proc.new { |title, file_extension = 'png'| ".game_data/#{title.downcase}/#{title.downcase}.#{file_extension}"          },
    :analysis_result => Proc.new { |title|                         ".game_data/#{title.downcase}/analysis_result.json"                         },
    :pdf             => Proc.new { |title, pdf_class|              ".game_data/#{title.downcase}/#{pdf_class.name}.pdf"                        },
    :pdf_preview     => Proc.new { |title, pdf_class, page_number| ".game_data/#{title.downcase}/#{pdf_class.name}_preview_#{page_number}.png" }
  }

  # Retrieve and save text
  def retrieve_source_text(title)
    raise ArgumentError, 'must pass a title (String)' unless title.is_a?(String)
    # retrieve the file
    file = Google::Cloud::Storage.new
      .bucket(BUCKET_NAME)
      .find_file(".game_data/#{title.downcase}/source_text.json")
    # return nil if there is no file
    return nil unless file
    # parse the JSON file into a hash
    data_hash = JSON.parse(file.download.string)
    # return a struct with the title, source_text and word count
    Struct.new(:title, :source_text, :word_count).new(
        data_hash['title'],
        data_hash['source_text'],
        data_hash['word_count']
      )
  end

  def save_source_text(title, source_text, word_count)
    raise ArgumentError, 'must pass a title (String)' unless title.is_a?(String)
    raise ArgumentError, 'must pass source_text (String)' unless source_text.is_a?(String)
    raise ArgumentError, 'must pass a word count (positive Integer)' unless word_count.is_a?(Integer) && word_count > 0
    Google::Cloud::Storage.new
      .bucket(BUCKET_NAME)
      .upload_file(
        StringIO.new(
          {
            "title"       => title,
            "source_text" => source_text,
            "word_count"  => word_count
          }.to_json
        ),
        BUCKET_PATH_FOR[:source_text].call(title),
        acl: "projectPrivate"
      )
  end


  # Retreive and save images
  def retrieve_image(title) # returns a Tempfile
    raise ArgumentError, 'must pass a title (String)' unless title.is_a?(String)
    # retrieve all matching files
    files = Google::Cloud::Storage.new
      .bucket(BUCKET_NAME)
      .find_files(prefix: BUCKET_PATH_FOR[:image].call(title).split('.')[0...-1].join('.')+'.') # drop the file extention but leave the final '.'
    download_to_tempfile(files.first)
  end

  def save_image(title, image_tempfile)
    raise ArgumentError, 'must pass a title (String)' unless title.is_a?(String)
    raise ArgumentError, 'must pass an image_tempfile (Tempfile)' unless image_tempfile.is_a?(Tempfile)
    begin
      Google::Cloud::Storage.new
        .bucket(BUCKET_NAME)
        .upload_file(
          image_tempfile.open,
          BUCKET_PATH_FOR[:image].call(title, image_tempfile.original_filename.split('.').last), # pass the title and file extention
          acl: "projectPrivate"
        )
    ensure
      image_tempfile.close
    end
  end


  # Retrieve and save analysises
  def retrieve_analysis_result(title)
    raise ArgumentError, 'must pass a title (String)' unless title.is_a?(String)
    # retrieve the file
    file = Google::Cloud::Storage.new
      .bucket(BUCKET_NAME)
      .find_file(BUCKET_PATH_FOR[:analysis_result].call(title))
    # return nil if there is no file
    return nil unless file
    # parse the JSON file into a hash
    data_hash = JSON.parse(file.download.string)
    # return AnalysisResult
    ExternalTextAnalyzer::AnalysisResult.new(
        data_hash["analysis_result"]["sentences"].map { |s| ExternalTextAnalyzer::Sentence.new(s["string"], s["sentiment"].to_f)},
        data_hash["analysis_result"]["entities"].map { |s| ExternalTextAnalyzer::Entity.new(s["string"], s["salience"].to_f, s["type"].to_sym, (s["is_proper"] == "true"))}
      )
  end

  def save_analysis_result(title, analysis_result)
    raise ArgumentError, 'must pass a title (String)' unless title.is_a?(String)
    raise ArgumentError, 'must pass an analysis_result (an AnalysisResult)' unless analysis_result.is_a?(ExternalTextAnalyzer::AnalysisResult)
    Google::Cloud::Storage.new
      .bucket(BUCKET_NAME)
      .upload_file(
        StringIO.new(
          {
            "title"     => title,
            "analysis_result" => analysis_result.to_h
          }.to_json
        ),
        BUCKET_PATH_FOR[:analysis_result].call(title), 
        acl: "projectPrivate"
      )
  end

  # Retreive and save PDFs
  def retrieve_pdf(title, pdf_class) # returns a Tempfile
    raise ArgumentError, 'must pass a title (String)' unless title.is_a?(String)
    raise ArgumentError, "must pass a pdf_class (#{BoardGame.game_component_classes.map(&:name).join(', ')})" unless BoardGame.game_component_classes.include?(pdf_class)
    # retrieve the file
    file = Google::Cloud::Storage.new
      .bucket(BUCKET_NAME)
      .file(BUCKET_PATH_FOR[:pdf].call(title, pdf_class))
    download_to_tempfile(file)
  end

  def save_pdf(title, pdf_tempfile, pdf_class)
    raise ArgumentError, 'must pass a title (String)' unless title.is_a?(String)
    raise ArgumentError, 'must pass a pdf_tempfile (Tempfile)' unless pdf_tempfile.is_a?(Tempfile)
    raise ArgumentError, "must pass a pdf_class (#{BoardGame.game_component_classes.map(&:name).join(', ')})" unless BoardGame.game_component_classes.include?(pdf_class)
    begin
      Google::Cloud::Storage.new
        .bucket(BUCKET_NAME)
        .upload_file(
          pdf_tempfile.open,
          BUCKET_PATH_FOR[:pdf].call(title, pdf_class),
          acl: "projectPrivate"
        )
    ensure
      pdf_tempfile.close
    end
  end

  # Retreive and save PDF preview images
  def retrieve_pdf_preview(title, pdf_class, page_number = 1) # returns a Tempfile
    raise ArgumentError, 'must pass a title (String)' unless title.is_a?(String)
    raise ArgumentError, "must pass a pdf_class (#{BoardGame.game_component_classes.map(&:name).join(', ')})" unless BoardGame.game_component_classes.include?(pdf_class)
    raise ArgumentError, "page_number must be a positive Integer" unless page_number.is_a?(Integer) && page_number > 0
    # retrieve the file
    file = Google::Cloud::Storage.new
      .bucket(BUCKET_NAME)
      .file(BUCKET_PATH_FOR[:pdf_preview].call(title, pdf_class, page_number))
    download_to_tempfile(file)
  end

  def save_pdf_preview(title, pdf_preview_tempfile, pdf_class, page_number = 1)
    raise ArgumentError, 'must pass a title (String)' unless title.is_a?(String)
    raise ArgumentError, 'must pass a pdf_preview_tempfile (Tempfile)' unless pdf_preview_tempfile.is_a?(Tempfile)
    raise ArgumentError, "page_number must be a positive Integer" unless page_number.is_a?(Integer) && page_number > 0
    begin
      Google::Cloud::Storage.new
        .bucket(BUCKET_NAME)
        .upload_file(
          pdf_preview_tempfile.open,
          BUCKET_PATH_FOR[:pdf_preview].call(title, pdf_class, page_number),
          acl: "projectPrivate"
        )
    ensure
      pdf_preview_tempfile.close
    end
  end



  def download_to_tempfile(file)
    return nil if file.nil?
    # return a Tempfile
    Tempfile.new.tap do |tf|
      begin
        tf.write(file.download.read)
        tf.rewind
      ensure
        tf.close
      end
      #tf.unlink # https://ruby-doc.org/stdlib-2.4.0/libdoc/tempfile/rdoc/Tempfile.html#class-Tempfile-label-Unlink+after+creation
    end
  end

end