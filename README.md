# Capture Ruby SDK

Official Ruby SDK for [Capture](https://capture.page) - Screenshot and content extraction API.

## Installation

Add to your Gemfile:

```ruby
gem "capture_page"
```

Or install directly:

```bash
gem install capture_page
```

## Quick Start

```ruby
require "capture"

client = Capture.new("your-api-key", "your-api-secret")

image_url = client.build_image_url("https://example.com")
puts image_url
```

## Features

- **Screenshot Capture**: Capture full-page or viewport screenshots as PNG/JPG
- **PDF Generation**: Convert web pages to PDF documents
- **Content Extraction**: Extract HTML and text content from web pages
- **Metadata Extraction**: Get page metadata (title, description, og tags, etc.)
- **Animated GIFs**: Create animated GIFs of page interactions
- **Browser Sessions**: Create stateful browser sessions and run actions
- **Zero Dependencies**: Uses only Ruby standard library

## Usage

### Initialize the Client

```ruby
require "capture"

client = Capture.new("your-api-key", "your-api-secret")

# Use edge endpoint for faster response times
client = Capture.new("your-api-key", "your-api-secret", use_edge: true)
```

### Building URLs

#### Image Capture

```ruby
image_url = client.build_image_url("https://example.com")

image_url = client.build_image_url("https://example.com", {
  "full" => true,
  "delay" => 2,
  "vw" => 1920,
  "vh" => 1080
})
```

#### PDF Capture

```ruby
pdf_url = client.build_pdf_url("https://example.com")

pdf_url = client.build_pdf_url("https://example.com", {
  "format" => "A4",
  "landscape" => true
})
```

#### Content Extraction

```ruby
content_url = client.build_content_url("https://example.com")
```

#### Metadata Extraction

```ruby
metadata_url = client.build_metadata_url("https://example.com")
```

#### Animated GIF

```ruby
animated_url = client.build_animated_url("https://example.com")
```

### Fetching Data

#### Fetch Image

```ruby
image_data = client.fetch_image("https://example.com")
File.binwrite("screenshot.png", image_data)
```

#### Fetch PDF

```ruby
pdf_data = client.fetch_pdf("https://example.com", { "full" => true })
File.binwrite("page.pdf", pdf_data)
```

#### Fetch Content

```ruby
content = client.fetch_content("https://example.com")
puts content["html"]
puts content["textContent"]
puts content["markdown"]
```

#### Fetch Metadata

```ruby
metadata = client.fetch_metadata("https://example.com")
puts metadata["metadata"]
```

#### Fetch Animated GIF

```ruby
gif_data = client.fetch_animated("https://example.com")
File.binwrite("animation.gif", gif_data)
```

### Browser Sessions

```ruby
session = client.create_session("maxTtlSeconds" => 300)
session_id = session["session"]["id"]

client.execute_action(session_id, "goto", "url" => "https://example.com")
screenshot = client.execute_action(session_id, "screenshot", "fullPage" => true)

client.close_session(session_id)
```

## Configuration Options

### Constructor Options

- `use_edge` (boolean): Use edge.capture.page instead of cdn.capture.page for faster response times

## API Endpoints

The SDK supports two base URLs:

- **CDN**: `https://cdn.capture.page` (default)
- **Edge**: `https://edge.capture.page` (when `use_edge: true`)

## License

MIT

## Links

- [Website](https://capture.page)
- [Documentation](https://docs.capture.page)
- [GitHub](https://github.com/techulus/capture-ruby)

## Support

For support, please visit [capture.page](https://capture.page) or open an issue on GitHub.
