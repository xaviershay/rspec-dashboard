require 'uri'
require 'json'
require 'net/http'
require 'pp'

github_uri = "https://api.github.com"
repos = %w(core support mocks expectations rails)

SCHEDULER.every '3m', :first_in => 0 do |job|
  result = repos.map do |repo|
    uri = URI("#{github_uri}/repos/rspec/rspec-#{repo}/issues?state=open&labels=Release+Blocker")
    response = Net::HTTP.get(uri) 
    data = JSON.parse(response)

    data.map do |issue|
      url = issue.fetch('html_url')

      {
        repo:  repo,
        label: "<a href='#{url}'>#{issue.fetch('title')}</a>",
        value: issue.fetch('comments'),
        url:   issue.fetch('html_url'),
        updated_at: Time.parse(issue.fetch('updated_at')).strftime("%Y-%m-%d")
      }
    end
  end.flatten
  send_event("rspec_issues", { items: result })
end
