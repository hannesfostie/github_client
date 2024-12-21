require 'httparty'

module Github
  class Client
    attr_accessor :repo_url

    def initialize(token, repo_url)
      # implement this method
      @token = token
      @repo_url = repo_url
    end

    def get(url)
      HTTParty.get("#{@repo_url}#{url}", headers: headers)
    end

    private


    def headers
      {
        'Authorization' => "Bearer #{@token}",
        'User-Agent' => 'Github Client'
      }
    end
  end
end
