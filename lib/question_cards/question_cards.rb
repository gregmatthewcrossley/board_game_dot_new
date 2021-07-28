class QuestionCards
  require_rel '/pdf/question_cards_pdf_generator.rb'
  include QuestionCardsPdfGenerator

  DEFAULT_NUMBER_OF_QUESTIONS = 100
  DEFAULT_NUMBER_OF_CHOICES = 4
  MINIMUM_ENTITIES_FOR_A_SET = 50
  MINIMUM_SENTENCES_FOR_A_SET = 50
  MINIMUM_CHARACTERS_FOR_A_QUESTION = 75
  MAXIMUM_CHARACTERS_FOR_A_QUESTION = 300
  PLAUSABLE_YEAR_RANGE = 30 # range of years for plausable dates
  BLANK_STRING = '________'

  attr_reader :all

  # def initialize(analyzed_text, number_of_questions = DEFAULT_NUMBER_OF_QUESTIONS, number_of_choices = DEFAULT_NUMBER_OF_CHOICES)
  #   raise ArgumentError, "number_of_questions must be a non-zero Integer" unless number_of_questions.is_a?(Integer) && number_of_questions > 0
  #   @number_of_questions = number_of_questions
  #   raise ArgumentError, "number_of_choices must be an Integer between 2 and 5" unless number_of_choices.is_a?(Integer) && (2..5).include?(number_of_choices)
  #   @number_of_choices = number_of_choices
  #   raise ArgumentError, 'must pass an ExternalTextAnalyzer::AnalysisResult when initializing' unless analyzed_text.is_a?(ExternalTextAnalyzer::AnalysisResult)
  #   entity_count = analyzed_text.entities.count
  #   unless entity_count >= MINIMUM_ENTITIES_FOR_A_SET
  #     raise ArgumentError, "text must have at least " + MINIMUM_ENTITIES_FOR_A_SET.to_s + " entities to generate a set of #{@number_of_questions} question cards (currently only " + entity_count.to_s + " entities)"
  #   end
  #   sentence_count = analyzed_text.sentences.count
  #   unless sentence_count >= MINIMUM_SENTENCES_FOR_A_SET
  #     raise ArgumentError, "text must have at least " + MINIMUM_SENTENCES_FOR_A_SET.to_s + " sentences to generate a set of #{@number_of_questions} question cards (currently only " + sentence_count.to_s + " sentences)"
  #   end
  #   @analyzed_text = analyzed_text

  #   # initialize an empty 'all' array (populated by the 'generate' method below)
  #   @all = []
  # end

  def initialize(topic)
    # validate the topic argument
    raise ArgumentError, "must pass a topic (a non-empty String)" unless topic.is_a?(String) && !topic.empty?
    @topic = topic
  end

  def preview_image
    "foo bar" #TO-DO: make this an image
  end

  def generate
    return self unless @all.empty?
    @all = @analyzed_text.entities.map { |entity| 
      Struct.new(:question, :choices, :answer).new(
        question_with_blank_for(entity), 
        (choices_for(entity) + [entity.string]).shuffle,
        entity.string
      )
    }.reject { |card|  
      card.question.empty? ||                       # drop any cards with blank questions
      /#{BLANK_STRING}/.match(card.question).nil? || # drop any questions without blanks
      card.choices.count != @number_of_choices      # drop any questions with not enough answers
    }.take(@number_of_questions)
    .shuffle
    return self
  end


  private


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
    @analyzed_text.sentences.map(&:string).select { |sentence|
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
      all_entity_strings_except(entity).sample(@number_of_choices - 1)
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
        .sample(@number_of_choices - 1)
    when date_string_is_a_month_and_a_year
      Array.new(100)
        .map { |i| Date.parse(date_string) + rand(-PLAUSABLE_YEAR_RANGE*365..1) }
        .select { |d| d != Date.parse(date_string) }
        .map { |d| d.strftime("%B %Y") }
        .uniq
        .sample(@number_of_choices - 1)
    when date_string_is_a_month_and_a_day
      Array.new(100)
        .map { |i| Date.parse(date_string) + rand(-PLAUSABLE_YEAR_RANGE*365..1) }
        .select { |d| d != Date.parse(date_string) }
        .map { |d| d.strftime("%B %-d") }
        .uniq
        .sample(@number_of_choices - 1)
    when date_string_is_a_full_date
      Array.new(100)
        .map { |i| Date.parse(date_string) + rand(-PLAUSABLE_YEAR_RANGE*365..1) }
        .select { |d| d != Date.parse(date_string) }
        .map { |d| d.strftime("%B %-d, %Y") }
        .uniq
        .sample(@number_of_choices - 1)
    else
      Date::MONTHNAMES.compact.sample(@number_of_choices - 1) # just return some random month names
    end
  end

  def all_entity_strings_except(entity)
    raise ArgumentError, "entity must be a ExternalTextAnalyzer::Entity" unless entity.is_a?(ExternalTextAnalyzer::Entity)
    entity_name_list = @analyzed_text.entities.select { |this_entity|
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