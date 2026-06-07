# frozen_string_literal: true

require "digest/md5"
require "net/http"
require "uri"
require "json"

class CaptureSessionsError < StandardError
  attr_reader :status, :body

  def initialize(status, body)
    message = body.is_a?(Hash) && body["error"].is_a?(String) ? body["error"] : "Capture Sessions API request failed with status #{status}"
    super(message)
    @status = status
    @body = body
  end
end

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

  def create_session(options = {})
    options = options.nil? ? {} : options
    raise TypeError, "options must be a Hash" unless options.is_a?(Hash)

    sessions_request("", :post, options)
  end

  def get_session(session_id)
    sessions_request("/#{escape_path(session_id)}", :get)
  end

  def close_session(session_id)
    sessions_request("/#{escape_path(session_id)}", :delete)
  end

  def execute_action(session_id, action_type, payload = {})
    payload = payload.nil? ? {} : payload
    raise TypeError, "payload must be a Hash" unless payload.is_a?(Hash)

    sessions_request("/#{escape_path(session_id)}/actions", :post, "type" => action_type, "payload" => payload)
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

  def sessions_bearer_token
    raise TypeError, "key and secret must be strings" unless @key.is_a?(String) && @secret.is_a?(String)
    raise ArgumentError, "Key and Secret is required" if @key.empty? || @secret.empty?

    ["#{@key}:#{@secret}"].pack("m0")
  end

  def session_url(path = "")
    "#{EDGE_URL}/v1/sessions#{path}"
  end

  def sessions_request(path, method, body = nil)
    uri = URI.parse(session_url(path))
    request = case method
              when :post then Net::HTTP::Post.new(uri)
              when :get then Net::HTTP::Get.new(uri)
              when :delete then Net::HTTP::Delete.new(uri)
              else raise ArgumentError, "unsupported sessions request method"
              end

    request["Authorization"] = "Bearer #{sessions_bearer_token}"
    unless body.nil?
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(body)
    end

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end
    response_body = parse_json_response(response.body)

    raise CaptureSessionsError.new(response.code.to_i, response_body) unless response.is_a?(Net::HTTPSuccess)

    response_body
  end

  def parse_json_response(body)
    return {} if body.nil? || body.empty?

    JSON.parse(body)
  rescue JSON::ParserError
    {}
  end

  def escape_path(value)
    raise ArgumentError, "session_id is required" if value.nil? || value.to_s.empty?

    URI.encode_www_form_component(value.to_s)
  end
end
