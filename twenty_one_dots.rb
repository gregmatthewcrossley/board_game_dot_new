require 'wikipedia'

class TwentyOneDots

  attr_reader :keyword

  def initialize(keyword)
    @keyword = keyword
    get_wikipedia_page
    raise ArgumentError, "no Wikipedia page exists for '" + @keyword + "'" unless wikipedia_page_text
  end

  def wikipedia_page_text
    @wikipedia_page.text
  end


  private


  def get_wikipedia_page
    @wikipedia_page = Wikipedia.find(@keyword)
  end

end