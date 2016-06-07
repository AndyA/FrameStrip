#!/usr/bin/env ruby

require 'bbc/redux'
require 'json'

config = JSON.parse(File.read("redux.json"))

client = BBC::Redux::Client.new({
  :username => config["username"], 
  :password => config["password"]
})

ARGF.each do |line|
  asset = client.asset(line)
  puts asset.ts_url
end


# vim:ts=2:sw=2:sts=2:et:ft=ruby

