require 'pry'
require 'wikipedia'
require "google/cloud/language"
ENV["GOOGLE_APPLICATION_CREDENTIALS"] = "google_application_credentials.json"

class TwentyOneDots

  MINIMUM_WORDS_FOR_A_PAGE = 1000
  NUMBER_OF_CARDS = 100
  NUMBER_OF_MULTIPLE_CHOICES = 4
  BLANK_STRING = '________'

  attr_reader :keyword, :wikipedia_page_title, :wikipedia_page_text, :entities

  def initialize(keyword)
    # initiate 
    @client = Google::Cloud::Language.language_service

    # save the keyword
    @keyword = keyword

    # try to find a coresponding Wikipedia page
    Wikipedia.find(@keyword).tap do |page|
      @wikipedia_page_title = page.title
      @wikipedia_page_text  = page.text
    end

    # validate the Wikipedia page, if any
    validate_presence_of_wikipedia_page
    validate_word_count_of_wikipedia_page

    # break the page's text into an array of entity hashes
    find_most_salient_entities
    
    # find other plausible entities
    populate_plausable_substitutes

    # find a sentence
    populate_sentences

  end


  private


  def validate_presence_of_wikipedia_page
    unless @wikipedia_page_text
      raise ArgumentError, "no Wikipedia page exists for '" + @keyword + "'" 
    end
  end

  def validate_word_count_of_wikipedia_page
    word_count = @wikipedia_page_text.split.count
    unless word_count >= MINIMUM_WORDS_FOR_A_PAGE
      raise ArgumentError, "the Wikipedia page must have at least " + MINIMUM_WORDS_FOR_A_PAGE.to_s + " words ('" + @keyword + "' has only " + word_count.to_s + " words)"
    end
  end

  def find_most_salient_entities
    @entities = analyze_text(@wikipedia_page_text).entities.map { |entity| 
        entity.to_h.select { |attribute| entity_attribute_whitelist.include? attribute }
      }.select {|entity| entity_type_whitelist.include? entity[:type] }.take(NUMBER_OF_CARDS)
  end

  def analyze_text(string)
    @client.annotate_text(document: {content: string, type: :PLAIN_TEXT})
  end

  def populate_plausable_substitutes
    @entities.each do |entity|
      entity[:plausable_substitutes] = plausable_substitutes_for(entity[:name], entity[:type])
    end
  end

  def plausable_substitutes_for(name, type)
    raise ArgumentError, "name must be a String" unless name.is_a? String
    raise ArgumentError, "type must be a Symbol" unless type.is_a? Symbol
    raise ArgumentError, "type must be one of: #{entity_type_whitelist.to_sentence}" unless entity_type_whitelist.include? type
    if type == :DATE then
      return Array.new(100).map { |i| name.to_i + rand(-15..15) }.select{ |n| n!=name.to_i }.sample(NUMBER_OF_MULTIPLE_CHOICES - 1)
    else
      return all_entity_names_except(name).sample(NUMBER_OF_MULTIPLE_CHOICES - 1)
    end
  end

  def all_entity_names_except(name)
    @entities.map { |entity| entity[:name] }.uniq.select{ |n| n!=name }
  end

  def populate_sentences
    @entities.each { |entity| entity[:sentence_with_blank] = sentence_with_blank_for(entity[:name]) }
      .select { |entity| entity[:sentence_with_blank] } # remove entities with no sentences
  end

  def sentence_with_blank_for(name)
    puts name
    sentence = sentence_for(name)
    return nil if sentence_for(name).nil?
    sentence_for(name).gsub(name, BLANK_STRING)
  end

  def sentence_for(name)
    @client.analyze_syntax(document: {content: @wikipedia_page_text, type: :PLAIN_TEXT})
      .sentences.map { |sentence| sentence.text.content }
      .select { |sentence| sentence.include? name }
      .sample
  end

  def entity_type_whitelist
    # see: https://cloud.google.com/natural-language/docs/reference/rest/v1/Entity#type
    %w(
      PERSON
      LOCATION
      ORGANIZATION
      EVENT
      WORK_OF_ART
      CONSUMER_GOOD
      DATE
    ).map(&:to_sym)
  end

  def entity_attribute_whitelist
    %w(
      name
      type
      salience
    ).map(&:to_sym)
  end

end