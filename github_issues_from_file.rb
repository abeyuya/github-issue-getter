#!/usr/bin/env ruby

require 'pp'
require 'pstore'
require 'yaml'
require 'octokit'

# 設定ファイル読み出し
if File.exists?("info.yml")
  CONFIG = YAML.load_file("info.yml")
else
  CONFIG = YAML.load_file("info_sample.yml")
end

# Project you want to export issues from
USER    = CONFIG["user"]
PROJECT = CONFIG["project"]

# 保存先ファイル
db = PStore.new("#{PROJECT}_issues.db")

# transactionメソッドの引数にtrueを指定すると読み込みモード
db.transaction(true) do
  #ループ
  db.roots.each { |key|
    puts "#{key}: #{db[key]}"
    pp db[key]
  }
end
