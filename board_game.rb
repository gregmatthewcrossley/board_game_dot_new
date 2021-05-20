# pry -r './board_game.rb' -e 'BoardGame.cli'

# load gems from our gemfile
require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

# load the CLI module
require_relative 'board_game_cli_module'

# load the name and description analyzer
require_relative 'name_and_description'

# load the text sourcer module
require_relative 'external_text_source'

# load the text analyser module
require_relative 'external_text_analyzer'

# load the card set class
require_relative 'card_set'

class BoardGame

  # add the CLI
  extend BoardGameCli

  attr_reader :topic, :name, :description 

  def initialize(topic, text: nil)
    raise ArgumentError, 'must pass a topic (string) when initializing' unless topic.is_a?(String) && !topic.empty?

    # save the topic
    @topic = topic.split().map(&:capitalize).join(' ')

    # generate a random name and description
    NameAndDescription.new(@topic).tap do |n|
      @name = n.name
      @description = n.description
    end

    # save or retrieve the text content
    @text ||= ExternalTextSource::WikipediaApi.new(@topic).text

    # analyze the text
    @analyzed_text = ExternalTextAnalyzer::GoogleNaturalLanguage.new(@text).analysis
  end

  def question_cards
    @question_cards ||= CardSet::Question.new(@analyzed_text).generate
  end

  def chance_cards 
    @chance_cards ||= CardSet::Chance.new(@analyzed_text).generate
  end

end