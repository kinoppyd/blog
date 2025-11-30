require 'open-uri'
require 'nokogiri'
require 'erb'
require 'fileutils'

module Jekyll
  class CardlinkTag < Liquid::Tag
    CACHE_DIR = "./_plugins/cache/"
    CACHE_FILE_NAME = "cardlink.yaml"
    CACHE_FILE_PATH = CACHE_DIR + CACHE_FILE_NAME

    def initialize(tag_name, url, _)
      super
      @tag_name = tag_name
      @url = url.gsub(" ", "")
    end

    def render(context)
      with_cache(@url) do |parser|
        ERB.new(File.read('./_plugins/cardlink.erb')).result(binding)
      end
    end

    def with_cache(url, &block)
      FileUtils.mkdir_p(CACHE_DIR)
      cache = File.exist?(CACHE_FILE_PATH) ? YAML.load_file(CACHE_FILE_PATH) : {}

      parser = OpenGraphProtocolParser.new(url).tap do |psr|
        if c = cache[url]
          psr.cached = true
          psr.link = c[:link]
          psr.favicon = c[:favicon]
          psr.site_name = c[:site_name]
          psr.title = c[:title]
          psr.description = c[:description]
          psr.og_image = c[:og_image]
        end
      end

      res = block.call(parser)

      cache[url] = {
        'link': parser.link,
        'favicon': parser.favicon,
        'site_name': parser.site_name,
        'title': parser.title,
        'description': parser.description,
        'og_image': parser.og_image,
      }

      File.open(CACHE_FILE_PATH, 'w') do |f|
        f.puts(YAML.dump(cache))
      end

      res
    end
  end
end

Liquid::Template.register_tag('cardlink', Jekyll::CardlinkTag)

class OpenGraphProtocolParser
  attr_reader :uri
  attr_writer :link, :favicon, :site_name, :title, :description, :og_image
  attr_accessor :cached

  def initialize(uri)
    @uri = uri
  end

  def link
    return @link if @cached

    node = content.xpath('//meta[@property="og:url"]')[0]
    return @link = node['content'] if node

    node = content.xpath('//link[@rel="canonical"]')[0]
    return @link = node['href'] if node

    return @link = @uri
  end

  def favicon
    return @favicon if @cached

    node = content.xpath('//link[@rel="icon" or @rel="shortcut icon"]')[0]
    if node
      path = node['href']
      @favicon = if path.start_with?('http')
                    path
                  elsif path.start_with?('.')
                    if uri.end_with?('/')
                      uri + path
                    else
                      uri.split('/')[0..-2].join('/') + '/' + path
                    end
                  else
                    base_url + path
                  end
    end
  end

  def site_name
    return @site_name if @cached

    node = content.xpath('//meta[@property="og:site_name"]')[0]
    return @site_name = node['content'] if node
  end

  def title
    return @title if @cached

    node = content.xpath('//meta[@property="og:title" or @property="twitter:title"]')[0]
    return @title = node['content'] if node

    node = content.xpath('//title')[0]
    return @title = node.text if node
  end

  def description
    return @description if @cached

    node = content.xpath('//meta[@property="og:description" or @name="description"]')[0]
    return @description = node['content'] if node
  end

  def og_image
    return @og_image if @cached

    node = content.xpath('//meta[@property="og:image" or @property="twitter:image"]')[0]
    return @og_image = node['content'] if node
  end

  def content
    @content ||= Nokogiri::HTML(URI.open(encode_multibyte(uri)))
  end

  def base_url
    return @base_url if @cached

    target = URI.parse(encode_multibyte(uri))
    @base_url = "#{target.scheme}://#{target.host}"
  end

  def encode_multibyte(url)
    url.split('').map { URI::UNSAFE =~ _1 ? CGI.escape(_1) : _1 }.join
  end
end
