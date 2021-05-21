class NameAndDescription

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

  attr_reader :name, :description

  def initialize(topic)
    raise ArgumentError, "must pass a topic (a non-empty String)" unless topic.is_a?(String) && !topic.empty?
    @topic = topic
    @name = TITLE_PHRASES.sample.gsub('_____', @topic)
    @description = DESCRIPTION_PHRASES.sample
  end

end