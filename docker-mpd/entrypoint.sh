#!/usr/bin/env bash

touch /mpd/cache/{tag_cache,state,sticker.sql} \
  && chmod -R 0777 /mpd/cache \
  && chown -R mpd /mpd/cache

## start
exec mpd --no-daemon /etc/mpd.conf "$@"
