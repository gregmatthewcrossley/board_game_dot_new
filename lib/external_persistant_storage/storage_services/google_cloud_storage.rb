module GoogleCloudStorage

  require 'stringio'

  BUCKET_NAME = 'board-game-dot-new'

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
        ".game_data/#{title.downcase}/source_text.json", 
        acl: "projectPrivate"
      )
  end


  # Retreive and save images
  def retrieve_image(title) # returns a Tempfile
    raise ArgumentError, 'must pass a title (String)' unless title.is_a?(String)
    # prepare the path
    prefix = ".game_data/#{title.downcase}/#{title.downcase}."
    # retrieve all matching files
    files = Google::Cloud::Storage.new
      .bucket(BUCKET_NAME)
      .find_files(prefix: prefix)
    return nil if files.empty?
    # return a Tempfile
    Tempfile.new.tap do |tf|
      tf.write(files.first.download.read)
      tf.rewind
      tf.unlink # https://ruby-doc.org/stdlib-2.4.0/libdoc/tempfile/rdoc/Tempfile.html#class-Tempfile-label-Unlink+after+creation
    end
  end

  def save_image(title, image_tempfile)
    raise ArgumentError, 'must pass a title (String)' unless title.is_a?(String)
    raise ArgumentError, 'must pass an image_tempfile (Tempfile)' unless image_tempfile.is_a?(Tempfile)
    # prepare the file's name and path
    file_extension = image_tempfile.original_filename.split('.').last
    path = ".game_data/#{title.downcase}/#{title.downcase}.#{file_extension}"
    Google::Cloud::Storage.new
      .bucket(BUCKET_NAME)
      .upload_file(
        image_tempfile,
        path,
        acl: "projectPrivate"
      )
  end


  # Retrieve and save analysises
  def retrieve_analysis_result(title)
    raise ArgumentError, 'must pass a title (String)' unless title.is_a?(String)
    # retrieve the file
    file = Google::Cloud::Storage.new
      .bucket(BUCKET_NAME)
      .find_file(".game_data/#{title.downcase}/analysis_result.json")
    # return nil if there is no file
    return nil unless file
    # parse the JSON file into a hash
    data_hash = JSON.parse(file.download.string)
    # return a struct with the title, sentences and entities
    Struct.new(:title, :sentences, :entities).new(
        data_hash['title'],
        data_hash['source_text'],
        data_hash['word_count']
      )
  end

  def save_analysis_result(title, sentences, entities)
    raise ArgumentError, 'must pass a title (String)' unless title.is_a?(String)
    raise ArgumentError, 'must pass sentences (an array of Hashes)' unless sentences.is_a?(Array) && sentences.first.is_a?(Hash)
    raise ArgumentError, 'must pass entities (an array of Hashes)' unless entities.is_a?(Array) && entities.first.is_a?(Hash)
    Google::Cloud::Storage.new
      .bucket(BUCKET_NAME)
      .upload_file(
        StringIO.new(
          {
            "title"     => title,
            "sentences" => sentences,
            "entities"  => entities
          }.to_json
        ),
        ".game_data/#{title.downcase}/analysis_result.json", 
        acl: "projectPrivate"
      )
  end

end