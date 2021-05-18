POSITIVE_CONSEQUENCE_LIST = [
    "Move forward * spaces.",
    "Take * dollars from the pot.",
    "Everyone gives you * dollars.",
  ]
NEGATIVE_CONSEQUENCE_LIST = [
    "Move back * spaces.",
    "Pay * dollars to the pot.",
    "Pay everyone * dollars."
  ]
CONSEQUENCE_RANGE = 5

def consequence_from(sentiment_score)
  raise ArgumentError, "sentiment_score must be a number between -1.0 and 1.0" unless (-1.0..1.0).include?(sentiment_score)
  consequence_list = sentiment_score.positive? ? POSITIVE_CONSEQUENCE_LIST : NEGATIVE_CONSEQUENCE_LIST
  consequence_list.sample.gsub('*', (CONSEQUENCE_RANGE*sentiment_score).round.to_i.abs.to_s)
end

set = @analyzed_text[:sentences].map { |sentence|
  {
    :sentence => sentence[:text][:content],
    :consequence => consequence_from(sentence[:sentiment][:score]),
    :sentiment_score => sentence[:sentiment][:score]
  }
}.sort { |a, b|
  a[:sentiment] <=> b[:sentiment]
}