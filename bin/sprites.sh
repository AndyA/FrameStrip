#!/bin/bash

ts="/data/d3/mpegts"
asset="/data/d3/asset"

find "$ts" -name '*.mpegts' -mmin +10 | while read mpeg; do
  perl bin/make-sprites.pl --output "$asset" "$mpeg"
done

# vim:ts=2:sw=2:sts=2:et:ft=sh

