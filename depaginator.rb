require_relative './client.rb'

module Github
  class Depaginator
    attr_accessor :first_page, :all_pages, :client

    def initialize(first_page, all_pages: false, client: nil)
      @first_page = first_page
      @all_pages = all_pages
      @client = client
    end

    def parsed_response
      if all_pages
        if page_count.to_i > 1
          other_pages = (2..page_count).to_a.map do |i|
            # Building the path like this is kind of sloppy. Turns out that the url and path we start
            # with is not actually the same as GH responds with in the "links" header.
            page_path = "/issues?" + uri_without_pagination.query + "&page=#{i}"
            page = client.get(page_path)
            JSON.parse(page.body)
          end

          [JSON.parse(first_page.body), other_pages].flatten
        end
      else
        JSON.parse(first_page.body)
      end
    end

    private

    # The below methods are entirely untested for edge cases such as missing header,
    # header lacking "last" link, non-200 responses... that kind of thing. There's also
    # no unit tests yet, obviously. I'd consider this very WIP and exploratory.
    def uri_without_pagination
      url = links['last'].to_s.sub(/&page=\d+/, '')
      URI.parse(url)
    end

    def links
      link_strings = first_page.headers['link']&.split(', ')
      return [] unless link_strings

      link_strings.inject({}) do |links, link_string|
        url, rel = *link_string.scan(/<(.*)>; rel=\"(.*)\"/).first
        links[rel] = url
        links
      end
    end

    def page_count
      last_page_url = links['last']
      return nil unless last_page_url

      uri = URI.parse(last_page_url)
      query = URI.decode_www_form(uri.query).to_h
      query['page'].to_i
    end
  end
end
