#!/bin/bash

ts="/data/d3/mpegts"
asset="/data/d3/asset"

while ssleep 60; do
  find "$ts" -name '*.mpegts' -mmin +10 -print0 \
    | xargs -0 -n 1 -P 4                        \
        perl bin/make-sprites.pl --output "$asset"
done

# vim:ts=2:sw=2:sts=2:et:ft=sh
