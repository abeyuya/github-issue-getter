require 'octokit'
require 'csv'
require 'date'
# Github credentials to access your private project
USERNAME="USER_NAME"
PASSWORD="SEKRIT"

# Project you want to export issues from
USER="REPO_OWNER"
PROJECT="REPO_NAME"

# Your local timezone offset to convert times
TIMEZONE_OFFSET="-4"

client = Octokit::Client.new(:login => USERNAME, :password => PASSWORD)

csv = CSV.new(File.open(File.dirname(__FILE__) + "/issues3.csv", 'w'))

puts "Initialising CSV file..."
#CSV Headers
header = [
  "Summary",
  "Description",
  "Date created",
  "Date modified",
  "Issue type",
  "Milestone",
  "Priority",
  "Status",
  "Reporter"
]
# We need to add a column for each comment, so this dictates how many comments for each issue you want to support
#20.times { header << "Comments" }
csv << header

puts "Getting issues from Github..."
temp_issues = []
issues = []
page = 0
begin
	page = page +1
	temp_issues = client.list_issues("#{USER}/#{PROJECT}", :state => "closed", :page => page)
	issues = issues + temp_issues;
end while not temp_issues.empty?
temp_issues = []
page = 0
begin
	page = page +1
	temp_issues = client.list_issues("#{USER}/#{PROJECT}", :state => "open", :page => page)
	issues = issues + temp_issues;
end while not temp_issues.empty?


puts "Processing #{issues.size} issues..."
issues.each do |issue|
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
  milestone = issue['milestone'] || "None"
  if (milestone != "None")
    milestone = milestone['title']
  end

  # Needs to match the header order above, date format are based on Jira default
  row = [
    issue['title'],
    issue['body'],
    DateTime.parse(issue['created_at']).new_offset(TIMEZONE_OFFSET).strftime("%d/%b/%y %l:%M %p"),
    DateTime.parse(issue['updated_at']).new_offset(TIMEZONE_OFFSET).strftime("%d/%b/%y %l:%M %p"),
    type,
    milestone,
    priority,
    issue['state'],
    issue['user']['login']
  ]
  csv << row
  end