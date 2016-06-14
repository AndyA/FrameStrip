#!/bin/bash

ts="/data/d3/mpegts"

while ssleep 60; do
  find "$ts" -name '*.mpegts' -mmin +10 -print0 | xargs -0 perl bin/meta.pl
done

# vim:ts=2:sw=2:sts=2:et:ft=sh

