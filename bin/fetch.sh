#!/bin/bash

list="ref/list.txt"
dir="/data/d3/mpegts"

mkdir -p "$dir"

ruby bin/dl.rb "$list" | while read url; do
  echo "Fetching $url"
  wget -P "$dir" -c "$url"
done

# vim:ts=2:sw=2:sts=2:et:ft=sh

