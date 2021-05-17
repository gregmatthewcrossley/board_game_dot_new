require 'pry'
require 'wikipedia'
require "google/cloud/language"
ENV["GOOGLE_APPLICATION_CREDENTIALS"] = "google_application_credentials.json"

class CardQuestionSet

  MINIMUM_WORDS_FOR_A_PAGE = 1000
  NUMBER_OF_QUESTIONS = 100
  QUESTION_WORD_LIMIT = 50
  NUMBER_OF_MULTIPLE_CHOICES = 4
  YEAR_SPREAD = 30 # range of years if the answers are a year
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

    # cull to the number of requested questions
    cull_questions

  end

  def questions_and_answers
    raise "not yet generated (hint: run 'generate' first)" unless @analyzed_text

    @entities.map { |entity| 
      {
        :question => entity[:sentence_with_blank],
        :choices  => ([entity[:name]] + entity[:plausable_substitutes]).shuffle,
        :answer   => entity[:name]
      }
    }
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
        entity
          .select { |attribute| entity_attribute_whitelist.include? attribute }
      }.select {|entity| entity_type_whitelist.include? entity[:type] }
      .uniq { |entity| entity[:name] }
    # determine whether the entity is a proper noun
    @entities.each do |entity|
      entity[:proper_noun?] = (entity[:mentions].first[:type] == :PROPER)
    end 
    # remove "mentions" from @entities
    @entities.each { |entity| entity.delete :mentions }
  end

  def parse_sentences
    @sentences = @analyzed_text[:sentences]
      .map { |sentence| sentence[:text][:content]} # get the sentences
      .select {|sentence| sentence[-1] == "."} # discard section titles
      .select {|sentence| sentence.split.count <= QUESTION_WORD_LIMIT } # discard long sentences
  end

  def generate_plausable_entity_substitutes
    @entities.each do |entity|
      entity[:plausable_substitutes] = plausable_substitutes_for(entity[:name], entity[:type], entity[:proper_noun?])
    end
    # remove any entities with no plausable substitutes
    @entities = @entities.select { |entity| entity[:plausable_substitutes] }
  end

  def plausable_substitutes_for(name, type, proper_noun)
    raise ArgumentError, "name must be a String" unless name.is_a? String
    raise ArgumentError, "type must be a Symbol" unless type.is_a? Symbol
    raise ArgumentError, "type must be one of: #{entity_type_whitelist.to_sentence}" unless entity_type_whitelist.include? type
    raise ArgumentError, "proper_noun must be True or False" unless [true, false].include? proper_noun
    if type == :DATE then
      return Array.new(100).map { |i| name.to_i + rand(-(YEAR_SPREAD / 2)..(YEAR_SPREAD / 2)) }.select{ |n| n!=name.to_i }.map(&:to_s).sample(NUMBER_OF_MULTIPLE_CHOICES - 1)
    else
      all_plausable_substitutes = all_entity_names_except(name, type, proper_noun)
      if all_plausable_substitutes.count >= (NUMBER_OF_MULTIPLE_CHOICES - 1)
        return all_plausable_substitutes.sample(NUMBER_OF_MULTIPLE_CHOICES - 1)
      else
        return false
      end
    end
  end

  def all_entity_names_except(name, type, proper_noun)
    @entities.select { |entity|
      entity[:name] != name && # drop the entity if it has the same name
      entity[:type] == type && # drop the entity unless it is the same type
      entity[:proper_noun?] == proper_noun # only keep either proper or regular nouns
    }.map { |entity| entity[:name] }.uniq
  end

  def generate_question_phrases
    @entities.each { |entity| entity[:sentence_with_blank] = sentence_with_blank_for(entity[:name]) }
      .select { |entity| entity[:sentence_with_blank] } # remove entities with no sentences
    # remove any entities with no question_phrases
    @entities = @entities.select { |entity| entity[:sentence_with_blank] }
  end

  def sentence_with_blank_for(name)
    sentence = sentence_for(name)
    return nil if sentence_for(name).nil?
    sentence_for(name).gsub(name, BLANK_STRING)
  end

  def sentence_for(name)
    @sentences.select { |sentence| sentence.include? name }.sample
  end

  def cull_questions
    @entities = @entities.sample(NUMBER_OF_QUESTIONS)
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
      mentions
    ).map(&:to_sym)
  end

end