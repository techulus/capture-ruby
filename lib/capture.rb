# frozen_string_literal: true

require "digest/md5"
require "net/http"
require "uri"
require "json"

class Capture
  API_URL = "https://cdn.capture.page"
  EDGE_URL = "https://edge.capture.page"

  attr_reader :key, :options

  def initialize(key, secret, options = {})
    @key = key
    @secret = secret
    options = options.nil? ? {} : options
    raise TypeError, "options must be a Hash" unless options.is_a?(Hash)
    @options = options
  end

  def build_image_url(url, options = {})
    build_url(url, "image", options)
  end

  def build_pdf_url(url, options = {})
    build_url(url, "pdf", options)
  end

  def build_content_url(url, options = {})
    build_url(url, "content", options)
  end

  def build_metadata_url(url, options = {})
    build_url(url, "metadata", options)
  end

  def build_animated_url(url, options = {})
    build_url(url, "animated", options)
  end

  def fetch_image(url, options = {})
    fetch_binary(build_image_url(url, options))
  end

  def fetch_pdf(url, options = {})
    fetch_binary(build_pdf_url(url, options))
  end

  def fetch_content(url, options = {})
    fetch_json(build_content_url(url, options))
  end

  def fetch_metadata(url, options = {})
    fetch_json(build_metadata_url(url, options))
  end

  def fetch_animated(url, options = {})
    fetch_binary(build_animated_url(url, options))
  end

  private

  def build_url(url, request_type, options)
    raise TypeError, "key and secret must be strings" unless @key.is_a?(String) && @secret.is_a?(String)
    raise ArgumentError, "Key and Secret is required" if @key.empty? || @secret.empty?
    raise ArgumentError, "url is required" if url.nil? || (url.is_a?(String) && url.empty?)
    raise TypeError, "url should be of type string (something like www.google.com)" unless url.is_a?(String)

    options = options.nil? ? {} : options
    raise TypeError, "options must be a Hash" unless options.is_a?(Hash)
    params = options.merge("url" => url)
    query_string = encode_query_string(params)
    token = generate_token(@secret, query_string)
    base_url = @options[:use_edge] || @options["useEdge"] ? EDGE_URL : API_URL

    "#{base_url}/#{@key}/#{token}/#{request_type}?#{query_string}"
  end

  def generate_token(secret, query_string)
    Digest::MD5.hexdigest("#{secret}#{query_string}")
  end

  def encode_query_string(params)
    filtered = params.each_with_object({}) do |(k, v), hash|
      next if v.nil?

      hash[k] = case v
                when true then "true"
                when false then "false"
                else v.to_s
                end
    end

    URI.encode_www_form(filtered)
  end

  def fetch_binary(url)
    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)
    raise "HTTP Error: #{response.code} #{response.message}" unless response.is_a?(Net::HTTPSuccess)

    response.body.force_encoding("BINARY")
  end

  def fetch_json(url)
    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)
    raise "HTTP Error: #{response.code} #{response.message}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end
end
