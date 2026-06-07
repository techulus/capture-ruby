# frozen_string_literal: true

require "capture"

RSpec.describe Capture do
  describe "#initialize" do
    it "stores key, secret, and options" do
      client = Capture.new("test_key", "test_secret")
      expect(client.key).to eq("test_key")
      expect(client.options).to eq({})
    end

    it "accepts use_edge option" do
      client = Capture.new("test_key", "test_secret", use_edge: true)
      expect(client.options[:use_edge]).to be true
    end

    it "raises error when constructor options is not a hash" do
      expect { Capture.new("test", "secret", "bad") }.to raise_error(TypeError, /options must be a Hash/)
    end
  end

  describe "#build_image_url" do
    it "builds a valid image URL" do
      client = Capture.new("test", "test")
      url = client.build_image_url("https://news.ycombinator.com/")
      expected = "https://cdn.capture.page/test/f37d5fb3ee4540a05bf4ffeed6dffa28/image?url=https%3A%2F%2Fnews.ycombinator.com%2F"
      expect(url).to eq(expected)
    end

    it "includes options in the URL" do
      client = Capture.new("test", "secret")
      url = client.build_image_url("https://news.ycombinator.com/", "full" => true, "delay" => 2)
      expect(url).to include("full=true")
      expect(url).to include("delay=2")
      expect(url).to include("url=https%3A%2F%2Fnews.ycombinator.com%2F")
    end
  end

  describe "#build_pdf_url" do
    it "builds a valid PDF URL" do
      client = Capture.new("test", "secret")
      url = client.build_pdf_url("https://example.com")
      expect(url).to include("/pdf?")
      expect(url).to include("url=https%3A%2F%2Fexample.com")
    end
  end

  describe "#build_content_url" do
    it "builds a valid content URL" do
      client = Capture.new("test", "secret")
      url = client.build_content_url("https://example.com")
      expect(url).to include("/content?")
      expect(url).to include("url=https%3A%2F%2Fexample.com")
    end
  end

  describe "#build_metadata_url" do
    it "builds a valid metadata URL" do
      client = Capture.new("test", "secret")
      url = client.build_metadata_url("https://example.com")
      expect(url).to include("/metadata?")
      expect(url).to include("url=https%3A%2F%2Fexample.com")
    end
  end

  describe "#build_animated_url" do
    it "builds a valid animated URL" do
      client = Capture.new("test", "secret")
      url = client.build_animated_url("https://example.com")
      expect(url).to include("/animated?")
      expect(url).to include("url=https%3A%2F%2Fexample.com")
    end
  end

  describe "edge URL" do
    it "uses edge URL when use_edge is true" do
      client = Capture.new("test", "secret", use_edge: true)
      url = client.build_image_url("https://example.com")
      expect(url).to start_with("https://edge.capture.page")
    end

    it "uses edge URL when useEdge string key is true" do
      client = Capture.new("test", "secret", "useEdge" => true)
      url = client.build_image_url("https://example.com")
      expect(url).to start_with("https://edge.capture.page")
    end

    it "uses CDN URL by default" do
      client = Capture.new("test", "secret")
      url = client.build_image_url("https://example.com")
      expect(url).to start_with("https://cdn.capture.page")
    end
  end

  describe "error handling" do
    it "raises error when key is empty" do
      client = Capture.new("", "secret")
      expect { client.build_image_url("https://example.com") }.to raise_error(ArgumentError, /Key and Secret/)
    end

    it "raises error when secret is empty" do
      client = Capture.new("test", "")
      expect { client.build_image_url("https://example.com") }.to raise_error(ArgumentError, /Key and Secret/)
    end

    it "raises error when url is nil" do
      client = Capture.new("test", "secret")
      expect { client.build_image_url(nil) }.to raise_error(ArgumentError, /url is required/)
    end

    it "raises error when url is not a string" do
      client = Capture.new("test", "secret")
      expect { client.build_image_url(123) }.to raise_error(TypeError, /url should be of type string/)
    end

    it "raises error when url is empty string" do
      client = Capture.new("test", "secret")
      expect { client.build_image_url("") }.to raise_error(ArgumentError, /url is required/)
    end

    it "raises error when key is not a string" do
      client = Capture.new(123, "secret")
      expect { client.build_image_url("https://example.com") }.to raise_error(TypeError, /key and secret must be strings/)
    end

    it "raises error when secret is not a string" do
      client = Capture.new("test", 456)
      expect { client.build_image_url("https://example.com") }.to raise_error(TypeError, /key and secret must be strings/)
    end

    it "raises error when options is not a hash" do
      client = Capture.new("test", "secret")
      expect { client.build_image_url("https://example.com", "bad") }.to raise_error(TypeError, /options must be a Hash/)
    end

    it "handles nil options without crashing" do
      client = Capture.new("test", "secret")
      url = client.build_image_url("https://example.com", nil)
      expect(url).to include("/image?")
      expect(url).to include("url=https%3A%2F%2Fexample.com")
    end
  end

  describe "option encoding" do
    let(:client) { Capture.new("test", "secret") }

    it "encodes boolean values" do
      url = client.build_image_url("https://example.com", "full" => true, "lazy" => false)
      expect(url).to include("full=true")
      expect(url).to include("lazy=false")
    end

    it "encodes numeric values" do
      url = client.build_image_url("https://example.com", "delay" => 5, "quality" => 80)
      expect(url).to include("delay=5")
      expect(url).to include("quality=80")
    end

    it "filters out nil values" do
      url = client.build_image_url("https://example.com", "none_value" => nil, "valid" => "value")
      expect(url).not_to include("none_value")
      expect(url).to include("valid=value")
    end

    it "keeps zero and false values" do
      url = client.build_image_url("https://example.com", "delay" => 0, "full" => false, "darkMode" => false)
      expect(url).to include("delay=0")
      expect(url).to include("full=false")
      expect(url).to include("darkMode=false")
    end
  end

  describe "token generation" do
    it "generates correct MD5 token" do
      client = Capture.new("test", "test")
      token = client.send(:generate_token, "test", "url=https%3A%2F%2Fnews.ycombinator.com%2F")
      expect(token).to eq("f37d5fb3ee4540a05bf4ffeed6dffa28")
    end
  end

  describe "sessions API" do
    class FakeSessionSuccess < Net::HTTPSuccess
      attr_reader :body

      def initialize(code, body)
        super("1.1", code, "OK")
        @body = body
      end
    end

    class FakeSessionNotFound < Net::HTTPNotFound
      attr_reader :body

      def initialize(body)
        super("1.1", "404", "Not Found")
        @body = body
      end
    end

    it "creates a session with bearer auth and JSON body" do
      stub_const("Capture::EDGE_URL", "https://edge.test")
      client = Capture.new("user_123", "secret")
      requests = []
      http = double("http")
      response = FakeSessionSuccess.new("201", JSON.generate("success" => true, "session" => { "id" => "sess_123" }))

      allow(http).to receive(:request) do |request|
        requests << request
        response
      end
      allow(Net::HTTP).to receive(:start).and_yield(http)

      result = client.create_session("maxTtlSeconds" => 300, "proxy" => true)

      expect(result["session"]["id"]).to eq("sess_123")
      expect(requests.first).to be_a(Net::HTTP::Post)
      expect(requests.first["Authorization"]).to eq("Bearer dXNlcl8xMjM6c2VjcmV0")
      expect(requests.first["Content-Type"]).to eq("application/json")
      expect(JSON.parse(requests.first.body)).to eq("maxTtlSeconds" => 300, "proxy" => true)
      expect(Net::HTTP).to have_received(:start).with("edge.test", 443, use_ssl: true)
    end

    it "gets, closes, and executes actions against session paths" do
      stub_const("Capture::EDGE_URL", "https://edge.test")
      client = Capture.new("user_123", "secret")
      paths = []
      http = double("http")
      response = FakeSessionSuccess.new("200", JSON.generate("success" => true, "session" => { "id" => "sess_123" }))

      allow(http).to receive(:request) do |request|
        paths << [request.method, request.path, request.body]
        response
      end
      allow(Net::HTTP).to receive(:start).and_yield(http)

      client.get_session("sess_123")
      client.close_session("sess_123")
      client.execute_action("sess_123", "goto", "url" => "https://example.com")

      expect(paths).to eq([
        ["GET", "/v1/sessions/sess_123", nil],
        ["DELETE", "/v1/sessions/sess_123", nil],
        ["POST", "/v1/sessions/sess_123/actions", JSON.generate("type" => "goto", "payload" => { "url" => "https://example.com" })]
      ])
    end

    it "raises a sessions error with status and body" do
      stub_const("Capture::EDGE_URL", "https://edge.test")
      client = Capture.new("user_123", "secret")
      http = double("http")
      response = FakeSessionNotFound.new(JSON.generate("success" => false, "error" => "Session not found"))

      allow(http).to receive(:request).and_return(response)
      allow(Net::HTTP).to receive(:start).and_yield(http)

      expect { client.get_session("missing") }.to raise_error(CaptureSessionsError) do |error|
        expect(error.status).to eq(404)
        expect(error.body).to eq("success" => false, "error" => "Session not found")
        expect(error.message).to eq("Session not found")
      end
    end

    it "creates a live session and screenshots example.com", :live do
      unless ENV["CAPTURE_LIVE_SESSIONS"] == "1"
        skip "set CAPTURE_LIVE_SESSIONS=1 with CAPTURE_KEY and CAPTURE_SECRET to run"
      end

      key = ENV.fetch("CAPTURE_KEY")
      secret = ENV.fetch("CAPTURE_SECRET")
      client = Capture.new(key, secret)

      created = client.create_session("maxTtlSeconds" => 120)
      session_id = created.dig("session", "id")
      expect(session_id).to be_a(String)
      expect(session_id).not_to be_empty

      begin
        goto_response = client.execute_action(session_id, "goto", "url" => "https://example.com")
        expect(goto_response["success"]).to be true

        screenshot_response = client.execute_action(session_id, "screenshot", "fullPage" => true)
        expect(screenshot_response["success"]).to be true

        screenshot =
          if screenshot_response["bodyBase64"]
            screenshot_response
          elsif screenshot_response.dig("result", "bodyBase64")
            screenshot_response["result"]
          elsif screenshot_response.dig("result", "screenshot", "bodyBase64")
            screenshot_response.dig("result", "screenshot")
          else
            screenshot_response["screenshot"]
          end

        expect(screenshot).to be_a(Hash), "screenshot response: #{screenshot_response.inspect}"
        expect(screenshot["contentType"]).to eq("image/png")
        expect(screenshot["bodyBase64"]).to be_a(String)
        expect(screenshot["bodyBase64"]).not_to be_empty
      ensure
        client.close_session(session_id) if session_id
      end
    end
  end
end
