require 'nokogiri'
require 'restclient'
require 'scraperwiki'
require 'cgi'
require 'set'

class Scraper
  def initialize
    @categories = []
  end

  def main
    init

    each_category do |category|
      fetch_category(category)
    end

    save
  end

  def init
    doc = fetch "https://www.clintonfoundation.org/contributors"
    @categories = doc.css('#edit-category > option').map { |e| e.attr('value') }
  end

  def each_category(&blk)
    @categories.each(&blk)
  end

  def fetch_category(category)
    doc = fetch "https://www.clintonfoundation.org/contributors?category=#{CGI.escape category}"
    parse_donors(doc)

    next_link = doc.css('.pager-next a').first

    while next_link
      doc = fetch "https://www.clintonfoundation.org#{next_link.attr('href')}"
      parse_donors(doc)
      next_link = doc.css('.pager-next a').first
    end
  end

  def parse_donors(doc)
    donors = doc.css('.views-table td').map { |e| e.text.strip.gsub(/\s*[\^\*]\s*/, '') }
    donors.each do |name|
      ScraperWiki.save_sqlite([:name], {name: name, last_seen: Time.now})
    end
  end

  def save

  end

  def fetch(url)
    puts url
    Nokogiri::HTML.parse(RestClient.get(url))
  end
end


Scraper.new.main