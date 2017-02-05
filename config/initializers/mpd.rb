MPD_CONNECTION = MPD.new(Rails.application.config.mpd[:host], Rails.application.config.mpd[:port], {:callbacks => true})
