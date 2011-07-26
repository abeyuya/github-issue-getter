require 'json'
require 'open-uri'
require 'csv'
require 'date'

# Github credentials to access your private project
USERNAME="myusername"
PASSWORD="mypassword"

# Project you want to export issues from
USER="someuser"
PROJECT="someproject"

# Your local timezone offset to convert times
TIMEZONE_OFFSET="+10"

BASE_URL="https://github.com/api/v2/json/issues"

csv = CSV.new(File.open(File.dirname(__FILE__) + "/issues.csv", 'w'))

puts "Initialising CSV file..."
# CSV Headers
header = [
  "Summary",
  "Description",
  "Date created",
  "Date modified",
  "Issue type",
  "Priority",
  "Status",
  "Reporter"
]
# We need to add a column for each comment, so this dictates how many comments for each issue you want to support
20.times { header << "Comments" }
csv << header

puts "Getting issues from Github..."
closed_issues = JSON.parse(open("#{BASE_URL}/list/#{USER}/#{PROJECT}/closed", 'r', { :http_basic_authentication => [USERNAME, PASSWORD] }).read)
open_issues = JSON.parse(open("#{BASE_URL}/list/#{USER}/#{PROJECT}/open", 'r', { :http_basic_authentication => [USERNAME, PASSWORD] }).read)

all_issues = closed_issues['issues'] + open_issues['issues']

puts "Processing #{all_issues.size} issues..."
all_issues.each do |issue|
  puts "Processing issue #{issue['number']}..."
  # Work out the type based on our existing labels
  case
    when issue['labels'].to_s =~ /Bug/i
      type = "Bug"
    when issue['labels'].to_s =~ /Feature/i
      type = "New feature"
    when issue['labels'].to_s =~ /Task/i
      type = "Task"
  end

  # Work out the priority based on our existing labels
  case
    when issue['labels'].to_s =~ /HIGH/i
      priority = "Critical"
    when issue['labels'].to_s =~ /MEDIUM/i
      priority = "Major"
    when issue['labels'].to_s =~ /LOW/i
      priority = "Minor"
  end

  # Needs to match the header order above, date format are based on Jira default
  row = [
    issue['title'],
    issue['body'],
    DateTime.parse(issue['created_at']).new_offset(TIMEZONE_OFFSET).strftime("%d/%b/%y %l:%M %p"),
    DateTime.parse(issue['updated_at']).new_offset(TIMEZONE_OFFSET).strftime("%d/%b/%y %l:%M %p"),
    type,
    priority,
    issue['state'],
    issue['user']
  ]

  if issue['comments'] > 0
    puts "Getting #{issue['comments']} comments for issue #{issue['number']} from Github..."
    # Get the comments
    comments = JSON.parse(open("#{BASE_URL}/comments/#{USER}/#{PROJECT}/#{issue['number']}", 'r', { :http_basic_authentication => [USERNAME, PASSWORD] }).read)

    comments['comments'].each do |c|
      # Date format needs to match hard coded format in the Jira importer
      comment_time = DateTime.parse(c['created_at']).new_offset(TIMEZONE_OFFSET).strftime("%m/%d/%y %r")

      # Map usernames for the comments importer
      comment_user = case c['user']
        when "Foo"
          "foo"
        when "baruser"
          "bar"
        when "myfunnyusername"
          "firstname"
      end

      # Put the comment in a format Jira can parse, removing #s as Jira thinks they're comments
      comment = "Comment: #{comment_user}: #{comment_time}: #{c['body'].gsub('#','')}"

      row << comment
    end
  end

  csv << row
end