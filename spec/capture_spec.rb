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
end
