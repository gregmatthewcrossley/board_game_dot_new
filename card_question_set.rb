require 'pry'
require 'wikipedia'
require "google/cloud/language"
ENV["GOOGLE_APPLICATION_CREDENTIALS"] = "google_application_credentials.json"

class CardQuestionSet

  MINIMUM_WORDS_FOR_A_PAGE = 1000
  NUMBER_OF_QUESTIONS = 100
  NUMBER_OF_MULTIPLE_CHOICES = 4
  BLANK_STRING = '________'

  attr_reader :topic, :wikipedia_page_title, :wikipedia_page_text, :analyzed_text, :entities, :sentences
  alias_method :all, :entities

  def initialize(topic)
    # save the topic
    @topic = topic

    # try to find a coresponding Wikipedia page
    Wikipedia.find(@topic).tap do |page|
      @wikipedia_page_title = page.title
      @wikipedia_page_text  = page.text
    end

    # validate the Wikipedia page, if any
    validate_presence_of_wikipedia_page
    validate_word_count_of_wikipedia_page

    # initiate Google Cloud Language client
    @client = Google::Cloud::Language.language_service

  end

  def generate

    # analyze the page's text
    analyze_text

    # break the analyzed_text into an array of entity hashes
    parse_entities

    # break the analyzed_text into an array of sentences
    parse_sentences
    
    # find other plausible entities
    generate_plausable_entity_substitutes

    # generate question phrases
    generate_question_phrases

  end

  def questions_and_answers
    raise "not yet generated (hint: run 'generate' first)" unless @analyzed_text

    @entities.map do |entity| 
      {
        :question => entity[:sentence_with_blank],
        :choices  => ([entity[:name]] + entity[:plausable_substitutes]).shuffle,
        :answer   => entity[:name]
      }
    end
  end


  private


  def validate_presence_of_wikipedia_page
    unless @wikipedia_page_text
      raise ArgumentError, "no Wikipedia page exists for '" + @topic + "'" 
    end
  end

  def validate_word_count_of_wikipedia_page
    word_count = @wikipedia_page_text.split.count
    unless word_count >= MINIMUM_WORDS_FOR_A_PAGE
      raise ArgumentError, "the Wikipedia page must have at least " + MINIMUM_WORDS_FOR_A_PAGE.to_s + " words ('" + @topic + "' has only " + word_count.to_s + " words)"
    end
  end

  def analyze_text
    # https://googleapis.dev/ruby/google-cloud-language-v1/latest/Google/Cloud/Language/V1/LanguageService/Client.html#annotate_text-instance_method
    @analyzed_text = @client.annotate_text(
      document: {
        content: @wikipedia_page_text, 
        type: :PLAIN_TEXT
      },
      features: {
        classify_text:              false,
        extract_document_sentiment: false,
        extract_entities:           true,
        extract_entity_sentiment:   false,
        extract_syntax:             true
      }).to_h
  end

  def parse_entities
    @entities = @analyzed_text[:entities].map { |entity| 
        entity.select { |attribute| entity_attribute_whitelist.include? attribute }
      }.select {|entity| entity_type_whitelist.include? entity[:type] }
      .uniq { |entity| entity[:name] }
      .take(NUMBER_OF_QUESTIONS)
  end

  def parse_sentences
    @sentences = @analyzed_text[:sentences].map { |sentence| 
        sentence[:text][:content]
      }.select {|sentence| sentence[-1] == "."} # discard section titles
  end

  def generate_plausable_entity_substitutes
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

  def generate_question_phrases
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
    @sentences.select { |sentence| sentence.include? name }.sample
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