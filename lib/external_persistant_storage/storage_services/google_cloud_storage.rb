module GoogleCloudStorage

  require 'stringio'

  BUCKET_NAME = 'board-game-dot-new'

  def save_text_source(title, text, word_count)
    raise ArgumentError, 'must pass a title (String)' unless title.is_a?(String)
    raise ArgumentError, 'must pass text (String)' unless text.is_a?(String)
    raise ArgumentError, 'must pass a word count (positive Integer)' unless word_count.is_a?(Integer) && word_count > 0
    Google::Cloud::Storage.new
      .bucket(BUCKET_NAME)
      .create_file(
        StringIO.new(
          {
            "title"      => title,
            "text"       => text,
            "word_count" => word_count
          }.to_json
        ),
        ".game_data/#{title.downcase}/text_source.json", 
        acl: "projectPrivate"
      )
  end

  def retrieve_text_source(title)
    raise ArgumentError, 'must pass a title (String)' unless title.is_a?(String)
    # retrieve the file
    file = Google::Cloud::Storage.new
      .bucket(BUCKET_NAME)
      .find_file(".game_data/#{title.downcase}/text_source.json")
    #return nil if there is no file
    return nil unless file
    # parse the JSON file into a hash
    data_hash = JSON.parse(file.download.string)
    # return a struct with the title, text and word count
    Struct.new(:title, :text, :word_count).new(
        data_hash['title'],
        data_hash['text'],
        data_hash['word_count']
      )
  end

  def save_image_source(title, image_tempfile, new_name = nil)
    raise ArgumentError, 'must pass a title (String)' unless title.is_a?(String)
    raise ArgumentError, 'must pass an image_tempfile (Tempfile)' unless image_tempfile.is_a?(Tempfile)
    raise ArgumentError, 'new_name must be nil or a String' unless new_name.is_a?(String) || new_name.nil?
    # prepare the file's name and path
    file_extension = image_tempfile.original_filename.split('.').last
    if new_name
      path = ".game_data/#{title.downcase}/game_piece_images/#{name}.#{file_extension}"
    else
      path = ".game_data/#{title.downcase}/main_image.#{file_extension}"
    end
    Google::Cloud::Storage.new
      .bucket(BUCKET_NAME)
      .create_file(
        image_tempfile,
        path,
        acl: "projectPrivate"
      )
  end

  def retrieve_image_source(title, game_piece_images = false)
    raise ArgumentError, 'must pass a title (String)' unless title.is_a?(String)
    raise ArgumentError, 'game_piece_images must be true or false' unless game_piece_images == true || game_piece_images == false
    # retrieve the file
    file = Google::Cloud::Storage.new
      .bucket(BUCKET_NAME)
      .find_file(".game_data/#{title.downcase}/text_source.json")
    #return nil if there is no file
    return nil unless file
    # parse the JSON file into a hash
    data_hash = JSON.parse(file.download.string)
    # return a struct with the title, text and word count
    Struct.new(:title, :text, :word_count).new(
        data_hash['title'],
        data_hash['text'],
        data_hash['word_count']
      )
  end

  def save_serialized_analysis_for_topic(topic)
    raise ArgumentError, 'must pass a topic (String)' unless topic.is_a?(String)
    # TO-DO
  end

  def retrieve_serialized_analysis_for_topic(topic)
    raise ArgumentError, 'must pass a topic (String)' unless topic.is_a?(String)
    # TO-DO
  end

end