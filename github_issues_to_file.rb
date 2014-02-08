#!/usr/bin/env ruby

# origin source
# https://gist.github.com/tkarpinski/2369729

require 'pp'
require 'octokit'
require 'pstore'
require 'yaml'

# 設定ファイル読み出し
if File.exists?("info.yml")
  CONFIG = YAML.load_file("info.yml")
else
  CONFIG = YAML.load_file("info_sample.yml")
end

# Github credentials to access your private project
USERNAME = CONFIG["username"]
PASSWORD = CONFIG["password"]

# Project you want to export issues from
USER    = CONFIG["user"]
PROJECT = CONFIG["project"]

# Your local timezone offset to convert times
TIMEZONE_OFFSET="0"

client = Octokit::Client.new(:login => USERNAME, :password => PASSWORD)

# 保存先ファイル
db = PStore.new("#{PROJECT}_issues.db")

# open, close 両方のissueを全て取得
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

# 取得したissue をシリアライズ保存
puts "Processing #{issues.size} issues..."
issues.each do |issue|
  puts "Processing issue #{issue['number']}..."

  # ハッシュと同じようにキーを指定して保存
  db.transaction do
    db["issue_#{issue['number']}"] = issue
  end # ここで保存される
end
