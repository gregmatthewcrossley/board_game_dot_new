class NameAndDescription

  WILDCARD_STRING = "_____"

  TITLE_PHRASES = [
    "The Game of _____",
    "_____-land!",
    "_____-opoly",
    "Hungry Hungry _____!",
    "_____-ium!",
    "Snakes and Ladders and _____!",
    "Fun with _____!",
    "_____ Madness!",
    "A Barrel of _____!"
  ]

  DESCRIPTION_PHRASES = [
    "Feel the excitement!",
    "Fun Guaranteed!",
    "More Thrilling than an Evening with Batman!",
    "Excitement for the Whole Family!",
    "The Fun Never Ends!",
    "You'll Never Notice You're Learning!",
    "The Terrifying Lows! The dizzying highs! The Creamy Middles!",
    "More than Mildly Amusing!",
    "A Somewhat Enjoyable Board Game!",
    "A Pleasant Way To Spend and Evening!",
    "A Boisterous and Convivial Board Game",
    "It's Back - In Board Game Form!",
    "A Truly Absurd Board Game!"
  ]

  EXTERNAL_STORAGE_FILENAME = 'name_and_description.json'

  attr_reader :topic, :name, :description

  def initialize(topic)
    raise ArgumentError, "must pass a topic (a non-empty String)" unless topic.is_a?(String) && !topic.empty?
    @topic = topic
    # generate or retrieve a name and description
    (retrieve_name_and_description || generate_name_and_description).tap do |name_and_description|
      @name        = name_and_description[:name]
      @description = name_and_description[:description]
    end
  end

  def quantity
    1
  end


  private


  def retrieve_name_and_description
    ExternalPersistentStorage.retrieve_hash(@topic, EXTERNAL_STORAGE_FILENAME)
  end

  def generate_name_and_description
    raise ArgumentError, "@topic cannot be nil" if @topic.nil?
    # generate a hash with name and description
    {
      :name => TITLE_PHRASES.sample.gsub('_____', @topic),
      :description => DESCRIPTION_PHRASES.sample
    }.tap do |h|
      # save this name and description for later
      ExternalPersistentStorage.save_hash(@topic, EXTERNAL_STORAGE_FILENAME, h)
    end  
  end

end