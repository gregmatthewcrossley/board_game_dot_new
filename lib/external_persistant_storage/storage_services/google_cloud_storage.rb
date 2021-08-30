module GoogleCloudStorage

  require 'stringio'

  # Google Cloud Storage bucket names and paths
  BUCKET_NAME = 'board-game-dot-new'
  BUCKET_ACCESSOR_INSTANCE = Google::Cloud::Storage.new.bucket(BUCKET_NAME)
  GAME_DATA_BUCKET_PATH  = Proc.new { |title, filename| 
    ".game_data/#{title.downcase}/#{filename}"
  }
  PUBLIC_PDF_BUCKET_PATH = Proc.new { |title, filename| 
    ".game_pdfs/#{title.downcase}/#{filename}"
  }

  def save_file(topic, filename, tempfile, public_pdf: false)
    validate_topic(topic)
    validate_filename(filename)
    validate_filename(filename, public_pdf: public_pdf)
    BUCKET_ACCESSOR_INSTANCE.upload_file(
      tempfile,
      public_pdf ?
        PUBLIC_PDF_BUCKET_PATH.call(topic, filename) : 
        GAME_DATA_BUCKET_PATH.call(topic, filename),
      acl: "projectPrivate"
    )
  end

  def retrieve_file(topic, filename, public_pdf: false)
    validate_topic(topic)
    validate_filename(filename, public_pdf: public_pdf)
    google_cloud_storage_file = BUCKET_ACCESSOR_INSTANCE.find_file(
        public_pdf ?
          PUBLIC_PDF_BUCKET_PATH.call(topic, filename) : 
          GAME_DATA_BUCKET_PATH.call(topic, filename)
      )
    return nil unless google_cloud_storage_file
    Tempfile.new.tap do |f| 
      f.write google_cloud_storage_file.download.read
      f.rewind
    end
  end

  def save_string(topic, filename, string)
    validate_topic(topic)
    validate_filename(filename)
    raise ArgumentError, 'must pass a string (String)' unless string.is_a?(String) and !string.empty?
    save_file(topic, filename, StringIO.new(string))
  end

  def retrieve_string(topic, filename)
    validate_topic(topic)
    validate_filename(filename)
    # retrieve the string file
    return nil unless string_file = retrieve_file(topic, filename)
    # read the string into a String
    return string_file.read rescue nil
  end
  
  def save_hash(topic, filename, hash)
    validate_topic(topic)
    validate_filename(filename)
    raise ArgumentError, 'must pass a hash (Hash)' unless hash.is_a?(Hash) and !hash.empty?
    save_string(topic, filename, hash.to_json)
  end

  def retrieve_hash(topic, filename)
    validate_topic(topic)
    validate_filename(filename)
    JSON.parse(retrieve_string(topic, filename)).transform_keys(&:to_sym) rescue nil
  end


  # Private methods


  def validate_topic(topic)
    raise ArgumentError, 'must pass a topic (String)' unless topic.is_a?(String) and !topic.empty?
  end
  # private_class_method :validate_topic

  def validate_filename(filename, public_pdf: false)
    raise ArgumentError, 'must pass a filename (String)' unless filename.is_a?(String) and !filename.empty?
    if public_pdf
      raise ArgumentError, "because public_pdf is true, the filename must have extention '.pdf'" unless filename.split('.').last == "pdf"
    end
  end
  # private_class_method :validate_filename

  def validate_tempfile(tempfile)
    raise ArgumentError, 'must pass a file (Tempfie)' unless tempfile.is_a?(Tempfile) and !string.empty?
    raise ArgumentError, 'tempfile cannot be empty' unless tempfile.length > 0
  end
  # private_class_method :validate_tempfile

end