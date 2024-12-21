require_relative './client.rb'
require_relative './depaginator.rb'
require 'json'
require 'dotenv'
Dotenv.load

module Github
  class Processor
    def initialize(client)
      @client = client
    end

    def issues(open: true, all_pages: false)
      state = open ? 'open' : 'closed'

      # In hindsight, I don't like making the initial request here and then passing the response
      # into the Depaginator. There's too many objects being passed around, making the code harder
      # to understand. If I were to refactor this, I believe my approach would be to create two
      # clients, one "regular" client and one which depaginates. Their interface would be the same,
      # they may even share code through mixins, but it would clean a lot of this mess up.
      first_page = @client.get("/issues?state=#{state}")
      issues = Depaginator.new(first_page, all_pages: all_pages, client: @client).parsed_response

      sorted_issues = issues.sort_by do |issue|
        if state == 'closed'
          issue['closed_at']
        else
          issue['created_at']
        end
      end.reverse

      sorted_issues.each do |issue|
        if issue['state'] == 'closed'
          puts "#{issue['title']} - #{issue['state']} - Closed at: #{issue['closed_at']}"
        else
          puts "#{issue['title']} - #{issue['state']} - Created at: #{issue['created_at']}"
        end
      end
    end
  end
end
# The URL to make API requests for the IBM organization and the jobs repository
# would be 'https://api.github.com/repos/ibm/jobs'.
Github::Processor.new(Github::Client.new(ENV['TOKEN'], ARGV[0])).issues(open: false, all_pages: true)
