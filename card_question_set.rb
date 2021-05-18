require 'pry' # for debugging
require 'date' # for generating plausable date substitutes
require 'wikipedia' # for retreiving Wikipedia articles
require 'google/cloud/language' # for analyzing text
ENV["GOOGLE_APPLICATION_CREDENTIALS"] = "google_application_credentials.json" 

class CardQuestionSet

  MINIMUM_WORDS_FOR_A_PAGE = 1000
  NUMBER_OF_QUESTIONS = 100
  QUESTION_WORD_LIMIT = 50
  NUMBER_OF_MULTIPLE_CHOICES = 4
  PLAUSABLE_YEAR_RANGE = 30 # range of years for plausable dates
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
    # @analyzed_text[:sentences].each do |sentence|
    #   binding.pry if sentence[:text][:content].include?("Luby")
    # end
    @sentences = @analyzed_text[:sentences]
      .map { |sentence| sentence[:text][:content]} # get the sentences
      .select {|sentence| sentence[-1] == "."} # discard section titles (ie sentences without a period at the end)
      .select {|sentence| sentence.split.count <= QUESTION_WORD_LIMIT } # discard long sentences
      .select {|sentence| sentence.split("=\n").count == 1 } # remove any Wikipedia headers (ie '== Illness and death ==')
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
      return plausable_date_substitutes(name)
    else
      all_plausable_substitutes = all_entity_names_except(name, type, proper_noun)
      if all_plausable_substitutes.count >= (NUMBER_OF_MULTIPLE_CHOICES - 1)
        return all_plausable_substitutes.sample(NUMBER_OF_MULTIPLE_CHOICES - 1)
      else
        return false
      end
    end
  end

  def plausable_date_substitutes(date_string)
    date_string_is_just_a_year = Proc.new { |string|
      string.split('').count == 4 && # check that it is 4 or fewer characters
      string.split('').map(&:to_i).sum > 0 # check that it is just numbers
    }

    date_string_is_a_month_and_a_year = Proc.new { |string| 
      string.split(' ').count == 2 && # the string is two words separated by a space
      Date::MONTHNAMES.compact.include?(string.split(' ').first) && # the first word is a month
      string.split(' ').last.split('').count <= 4 && # check that it is 4 or fewer characters
      string.split(' ').last.split('').map(&:to_i).sum > 0 # check that it is just numbers
    }

    date_string_is_a_full_date = Proc.new { |string| 
      begin
        Date.parse(string).is_a? Date
      rescue
        false
      end
    }

    case date_string
    when date_string_is_just_a_year
      Array.new(100)
        .map { |i| date_string.to_i + rand(-PLAUSABLE_YEAR_RANGE..1) }
        .select { |d| d != date_string.to_i }
        .map(&:to_s)
        .uniq
        .sample(NUMBER_OF_MULTIPLE_CHOICES - 1)
    when date_string_is_a_month_and_a_year
      Array.new(100)
        .map { |i| Date.parse(date_string) + rand(-PLAUSABLE_YEAR_RANGE*365..1) }
        .select { |d| d != Date.parse(date_string) }
        .map { |d| d.strftime("%B %Y") }
        .uniq
        .sample(NUMBER_OF_MULTIPLE_CHOICES - 1)
    when date_string_is_a_full_date
      Array.new(100)
        .map { |i| Date.parse(date_string) + rand(-PLAUSABLE_YEAR_RANGE*365..1) }
        .select { |d| d != Date.parse(date_string) }
        .map { |d| d.strftime("%B %-d, %Y") }
        .uniq
        .sample(NUMBER_OF_MULTIPLE_CHOICES - 1)
    else
      Date::MONTHNAMES.compact.sample(NUMBER_OF_MULTIPLE_CHOICES - 1) # just return some random month names
    end
  end

  def all_entity_names_except(name, type, proper_noun)
    @entities.select { |entity|
      entity[:name] != name && # drop the entity if it has the same name
      entity[:type] == type && # drop the entity unless it is the same type
      entity[:proper_noun?] == proper_noun # only keep either proper or regular nouns
    }.map { |entity| entity[:name] }.uniq # remove duplicates
    .map { |name| 
      if proper_noun
        if name.split(', ').count == 2 # reverse any names with commas (ie 'Smith, John')
          name.split(', ').map(&:capitalize).reverse.join(' ')
        else
          name.split(' ').map(&:capitalize).join(' ')
        end
      else
        name.downcase
      end # match capitalization to noun type
    }
  end

  def generate_question_phrases
    @entities.each { |entity| entity[:sentence_with_blank] = sentence_with_blank_for(entity[:name]) }
      .select { |entity| entity[:sentence_with_blank] } # remove entities with no sentences
    # remove any entities with no question_phrases
    @entities = @entities.select { |entity| entity[:sentence_with_blank] }
  end

  def sentence_with_blank_for(name)
    sentence = sentence_for(name)
    return nil if sentence_for(name).nil? # skip any blank sentences
    begin
      return nil if sentence_for(name).gsub('-','~~~~~').delete(name.gsub('-','~~~~~')).split('').count == 0 # skip sentences only containing the entity name (the ~~~~ is to make sure there aren't any dashes in the string, which messed up the delete() method)
    rescue ArgumentError
      binding.pry
    end
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