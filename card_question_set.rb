=begin

to run in terminal: 

pry -r ./card_question_set.rb -e CardQuestionSet.cli

=end

# load gems from our gemfile
require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

# load the CLI module
require_relative 'card_question_set_cli_interface_module'

# save the google app credentials as an environment variable, if avaliable
ENV["GOOGLE_APPLICATION_CREDENTIALS"] ||= "google_application_credentials.json" 


class CardQuestionSet

  extend CardQuestionSetCliInterface

  MINIMUM_WORDS_FOR_A_PAGE = 1000
  DEFAULT_NUMBER_OF_QUESTIONS = 100
  MINIMUM_CHARACTERS_FOR_A_QUESTION = 75
  MAXIMUM_CHARACTERS_FOR_A_QUESTION = 300
  NUMBER_OF_MULTIPLE_CHOICES = 4
  PLAUSABLE_YEAR_RANGE = 30 # range of years for plausable dates
  BLANK_STRING = '________'

  attr_reader :topic, :wikipedia_page_title, :wikipedia_page_text, :analyzed_text, :entities, :sentences
  alias_method :all, :entities

  def initialize(topic)
    raise ArgumentError, 'must pass a topic (string) when initializing' unless topic.is_a?(String)

    # save the topic
    @topic = topic.split().map(&:capitalize).join(' ')

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

  def generate(count: DEFAULT_NUMBER_OF_QUESTIONS)

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
    cull_questions_to(count)

    # return the card question set, now generated
    return self

  end

  def questions_and_answers
    raise "not yet generated (hint: run 'generate' first)" unless @analyzed_text

    @entities.map { |entity| 
      {
        :question => entity[:sentence_with_blank],
        :choices  => ([entity[:name]] + entity[:plausable_substitutes]).shuffle,
        :answer   => entity[:name]
      }
    }.shuffle
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

  def two_sentences_missing_a_space?(string)
    # The Wikipedia API sometimes returns two sentences without a space
    # between them (ie when paragraphs end and a new one starts). 
    # This method is used to detect such errors
    /[A-Za-z][.][A-Za-z]/.match(string) ? true : false
  end

  def parse_entities
    @entities = @analyzed_text[:entities].map { |entity| 
        entity
          .select { |attribute| entity_attribute_whitelist.include? attribute }
      }.select { |entity| entity_type_whitelist.include? entity[:type] }
      .uniq { |entity| entity[:name] } # remove any duplicates
      .reject { |entity| two_sentences_missing_a_space?(entity[:name]) } # remove any double words with periods and no spaces (ie "end.But")
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
      .select {|sentence| sentence[-1] == "."} # discard section titles (ie sentences without a period at the end)
      .select {|sentence| sentence.split('').count >= MINIMUM_CHARACTERS_FOR_A_QUESTION } # discard short sentences
      .select {|sentence| sentence.split('').count <= MAXIMUM_CHARACTERS_FOR_A_QUESTION } # discard long sentences
      .select {|sentence| sentence.split("=\n").count == 1 } # remove any Wikipedia headers (ie '== Illness and death ==')
    # fix any double-sentences with missing spaces between them (ie "... ever after.And then, the big bad wolf...")
    @sentences = @sentences.map { |sentence|
      if two_sentences_missing_a_space?(sentence) # if this sentence is a double sentence with missing spaces between them
        start_of_second_sentence = /[.]\S+/.match(sentence).to_s # find the start of the second sentence
        two_sentences = sentence.split(start_of_second_sentence) # split the sentences
        return sentence unless two_sentences.count == 2 # in case the split returned just one sentence
        two_sentences[0] = two_sentences[0] + "." # add a period back into the end of the first sentence
        two_sentences[1] = start_of_second_sentence.gsub('.','') + two_sentences[1]
        # split the sentences into two
        two_sentences # an array of the two sentences
      else
        sentence
      end
    }.flatten # flatten any two-sentence arrays into the main @sentences array
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

    date_string_is_a_month_and_a_day = Proc.new { |string| 
      string.split(' ').count == 2 && # the string is two words separated by a space
      Date::MONTHNAMES.compact.include?(string.split(' ').first) && # the first word is a month
      string.split(' ').last.split('').count <= 2 && # check that it is 4 or fewer characters
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
    when date_string_is_a_month_and_a_day
      Array.new(100)
        .map { |i| Date.parse(date_string) + rand(-PLAUSABLE_YEAR_RANGE*365..1) }
        .select { |d| d != Date.parse(date_string) }
        .map { |d| d.strftime("%B %-d") }
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
    all_entity_names = @entities.select { |entity|
      entity[:name] != name && # drop the entity if it has the same name
      entity[:type] == type && # drop the entity unless it is the same type
      entity[:proper_noun?] == proper_noun # only keep either proper or regular nouns
    }.map { |entity| 
      entity[:name]
    }.select { |entity_name| # make sure the name isn't just all numbers (ie an ISBN number like 978-0-452-00849-6)
      /[A-Za-z]/.match(entity_name)
    }.map { |entity_name| 
      if proper_noun # match capitalization to noun type
        if entity_name.split(', ').count == 2 # reverse any names with commas (ie 'Smith, John')
          entity_name.split(', ').map(&:capitalize).reverse.join(' ')
        else
          entity_name.split(' ').map(&:capitalize).join(' ')
        end
      else
        entity_name.downcase
      end 
    }.map { |entity_name|
      if is_plural?(name)
        entity_name.pluralize
      else
        entity_name.singularize
      end
    }.uniq # remove duplicates

    all_entity_names.reject { |entity_name| # make sure each entity name isn't a substring of another
      (all_entity_names - [entity_name]).map { |n|
        n.include? entity_name
      }.any?
    }
  end

  def is_singular?(noun)
    noun.singularize == noun
  end

  def is_plural?(noun)
    noun.pluralize == noun
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
    return nil if sentence_for(name).gsub('-','~~~~~').delete(name.gsub('-','~~~~~')).split('').count == 0 # skip sentences only containing the entity name (the ~~~~ is to make sure there aren't any dashes in the string, which messed up the delete() method)
    sentence_for(name).gsub(name, BLANK_STRING)
  end

  def sentence_for(name)
    name_variations = [
      ". #{name.capitalize} ", # start of sentence
      " #{name} ",             # mid sentence
      " #{name}.",             # end of sentene
    ]
    @sentences.select { |sentence|
      name_variations.map { |variation|
        sentence.include? variation
      }.any?
    }.sample
  end

  def cull_questions_to(count)
    @entities = @entities.sample(count)
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