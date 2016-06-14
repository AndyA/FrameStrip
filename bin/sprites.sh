#!/bin/bash

ts="/data/d3/mpegts"
asset="/data/d3/asset"

find "$ts" -name '*.mpegts' -mmin +10 -print0 \
  | xargs -0 -n 1 -P 10                       \
      perl bin/make-sprites.pl --output "$asset"

# vim:ts=2:sw=2:sts=2:et:ft=sh
