class QuestionCards
  require_rel '/pdf/question_cards_pdf_generator.rb'
  include QuestionCardsPdfGenerator

  NUMBER_OF_QUESTIONS = 100
  NUMBER_OF_CHOICES = 4
  MINIMUM_ENTITIES_FOR_A_SET = 50
  MINIMUM_SENTENCES_FOR_A_SET = 50
  MINIMUM_CHARACTERS_FOR_A_QUESTION = 75
  MAXIMUM_CHARACTERS_FOR_A_QUESTION = 300
  PLAUSABLE_YEAR_RANGE = 30 # range of years for plausable dates
  BLANK_STRING = '________'

  EXTERNAL_STORAGE_FILENAME = 'question_cards.json'

  attr_reader :topic, :analysis_result, :question_cards

  def initialize(topic)
    # validate the topic argument
    raise ArgumentError, "must pass a topic (a non-empty String)" unless topic.is_a?(String) && !topic.empty?
    @topic = topic
    @analysis_result = ExternalTextAnalyzer::Any.new(@topic).analysis_result
    raise ArgumentError, "no ExternalTextAnalyzer::AnalysisResult could be found for #{@topic}" unless @analysis_result.is_a?(ExternalTextAnalyzer::AnalysisResult)
    unless @analysis_result.entities.count >= MINIMUM_ENTITIES_FOR_A_SET
      raise ArgumentError, "text must have at least " + MINIMUM_ENTITIES_FOR_A_SET.to_s + " entities"
    end
    unless @analysis_result.sentences.count >= MINIMUM_SENTENCES_FOR_A_SET
      raise ArgumentError, "text must have at least " + MINIMUM_SENTENCES_FOR_A_SET.to_s + " sentences"
    end
    @question_cards = retrieve_question_cards || generate_question_cards
  end

  def quantity
    NUMBER_OF_QUESTIONS
  end


  private


  def retrieve_question_cards
    ExternalPersistentStorage.retrieve_hash(@topic, EXTERNAL_STORAGE_FILENAME)
  end

  def generate_question_cards
    @analysis_result.entities.map { |entity| 
      Struct.new(:question, :choices, :answer).new(
        question_with_blank_for(entity), 
        (choices_for(entity) + [entity.string]).shuffle,
        entity.string
      )
    }.reject { |card|  
      card.question.empty? ||                        # drop any cards with blank questions
      /#{BLANK_STRING}/.match(card.question).nil? || # drop any questions without blanks
      card.choices.count != NUMBER_OF_CHOICES        # drop any questions with not enough answers
    }.take(NUMBER_OF_QUESTIONS)
    .shuffle
  end

  def question_with_blank_for(entity)
    raise ArgumentError, "entity must be a ExternalTextAnalyzer::Entity" unless entity.is_a?(ExternalTextAnalyzer::Entity)
    question_without_blank = sentence_including(entity)
    question_without_blank ? question_without_blank.gsub(/#{entity.string}/i,BLANK_STRING) : ""
  end

  def sentence_including(entity)
    raise ArgumentError, "entity must be a ExternalTextAnalyzer::Entity" unless entity.is_a?(ExternalTextAnalyzer::Entity)
    entity_string_variations = [
      "#{entity.string.capitalize} ", # start of sentence
      " #{entity.string} ",             # mid sentence
      " #{entity.string}.",             # end of sentene
    ]
    @analysis_result.sentences.map(&:string).select { |sentence|
      entity_string_variations.map { |variation|
        sentence.include? variation
      }.any?
    }.sample
  end

  def choices_for(entity)
    raise ArgumentError, "entity must be a ExternalTextAnalyzer::Entity" unless entity.is_a?(ExternalTextAnalyzer::Entity)
    if entity.type == :DATE then
       plausable_date_substitutes(entity)
    else
      all_entity_strings_except(entity).sample(NUMBER_OF_CHOICES - 1)
    end
  end

  def plausable_date_substitutes(entity)
    raise ArgumentError, "entity must be a ExternalTextAnalyzer::Entity" unless entity.is_a?(ExternalTextAnalyzer::Entity)
    date_string = entity.string

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
        .sample(NUMBER_OF_CHOICES - 1)
    when date_string_is_a_month_and_a_year
      Array.new(100)
        .map { |i| Date.parse(date_string) + rand(-PLAUSABLE_YEAR_RANGE*365..1) }
        .select { |d| d != Date.parse(date_string) }
        .map { |d| d.strftime("%B %Y") }
        .uniq
        .sample(NUMBER_OF_CHOICES - 1)
    when date_string_is_a_month_and_a_day
      Array.new(100)
        .map { |i| Date.parse(date_string) + rand(-PLAUSABLE_YEAR_RANGE*365..1) }
        .select { |d| d != Date.parse(date_string) }
        .map { |d| d.strftime("%B %-d") }
        .uniq
        .sample(NUMBER_OF_CHOICES - 1)
    when date_string_is_a_full_date
      Array.new(100)
        .map { |i| Date.parse(date_string) + rand(-PLAUSABLE_YEAR_RANGE*365..1) }
        .select { |d| d != Date.parse(date_string) }
        .map { |d| d.strftime("%B %-d, %Y") }
        .uniq
        .sample(NUMBER_OF_CHOICES - 1)
    else
      Date::MONTHNAMES.compact.sample(NUMBER_OF_CHOICES - 1) # just return some random month names
    end
  end

  def all_entity_strings_except(entity)
    raise ArgumentError, "entity must be a ExternalTextAnalyzer::Entity" unless entity.is_a?(ExternalTextAnalyzer::Entity)
    entity_name_list = @analysis_result.entities.select { |this_entity|
      this_entity.string != entity.string && # drop the entity if it has the same string
      this_entity.type == entity.type && # drop the entity unless it is the same type
      this_entity.is_proper? == entity.is_proper? && # drop the entity unless its noun type matches (proper or regular)
      /[A-Za-z]/.match(this_entity.string) # make sure the string isn't just all numbers (ie an ISBN number like 978-0-452-00849-6)
    }.map { |entity| 
      if entity.is_proper? # match capitalization to noun type
        if entity.string.split(', ').count == 2 # reverse any names with commas (ie 'Smith, John')
          entity.string.split(', ').map(&:capitalize).reverse.join(' ')
        else
          entity.string.split(' ').map(&:capitalize).join(' ')
        end
      else
        entity.string.downcase
      end 
    }.map { |entity_name| # match plurality
      if is_plural?(entity_name)
        entity_name.pluralize
      else
        entity_name.singularize
      end
    }

    entity_name_list.reject { |entity_name| # make sure each entity name isn't a substring of another
      (entity_name_list - [entity_name]).map { |n|
        n.include? entity_name
      }.any?
    }.uniq
  end

  def is_singular?(noun)
    noun.singularize == noun
  end

  def is_plural?(noun)
    noun.pluralize == noun
  end

end