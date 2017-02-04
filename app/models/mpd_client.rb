class MpdClient

  attr_accessor :connection

  def self.client
    mpdclient = new
    mpdclient.connection = MPD.new('localhost', 6600, {:callbacks => true})
    mpdclient.connect
    mpdclient
  end

  def redis
    @redis ||= Redis.new(host: 'localhost', port: 6379)
  end

  def connect
    unless connection.connected?

      connection.connect
      connection.consume = false
      connection.random = false
      connection.repeat = false
      connection.single = false

      connection.on :songid do |s|
        current_song_changes(s)
      end

      connection.on :nextsongid do |s|
        next_song_changed(s)
      end

      connection.on :updating_db do |job_id|
      end
    end
  end



  ##
  ## full index of db to elasticsearch by recursively reading database
  ## works but slow
  ##

  def index_database
    index_children('')
  end

  def index_children(path)
    contents = connection.send_command(:lsinfo, path)

    if contents.is_a?(Hash)
      index_content(contents)

    elsif contents.is_a?(Array)
      contents.each do |c|
        index_content(c)
      end
    end
  end

  def index_content(c)
    index_playlist_file(c) if c.has_key?(:playlist)

    if c.has_key?(:directory)
      Rails.logger.debug("index: directory #{c[:directory]}")
      index_directory(c)
    end

    index_file(c) if c.has_key?(:file)
  end

  def index_directory(c)
    if c[:directory].is_a?(Array)
      c[:directory].each do |path|
        index_children(path)
      end
    else
      index_children(c[:directory])
    end
  end

  def index_file(c)
    Song.update(c)
  end

  def index_playlist_file(hash)
    # s = Song.update(hash)
  end



  ##
  ## incremental index by reading mpd log
  ## parse update log with filebeat into redis and index from redis to elasticsearch
  ##

  def index_incremental
    while true
      item = JSON.parse(redis.lpop('music_database'))
      case item['message']

      when / : update: added /
        path = item['message'].gsub(/^.*? : update: added /, '')
        if !path.blank?
          Rails.logger.debug("Add from log #{path}")

          c = connection.send_command(:lsinfo, path)
          index_file(c) if c.has_key?(:file)
        end

      when / : update: updating /
        path = item['message'].gsub(/^.*? : update: updating /, '')
        if !path.blank?
          Rails.logger.debug("Update from log #{path}")

          c = connection.send_command(:lsinfo, path)
          index_file(c) if c.has_key?(:file)
        end

      when / : update: removing /
        path = item['message'].gsub(/^.*? : update: removing /, '')
        if !path.blank?
          Rails.logger.debug("Delete from log #{path}")

          Song.find(path).destroy rescue true
        end
      end
    end
  rescue
    Rails.logger.info("Broke from indexing loop")
  end




  def current_song_changed_callback(s)
    Rails.logger.debug "Current song changed #{s}"
  end

  def next_song_changed_callback(s)
    Rails.logger.debug "Next song changed: #{s}"
  end

  ## add single file to position in queue
  def queue_file(file, position)
    connection.addid(file, position)
  end

  def queue_playlist(file, playlist_range, position)
    current_size = connection.queue.size
    ## load playlist to queue
    playlist = MPD::Playlist.new(connection, file)
    playlist.load(playlist_range)
    if position
      connection.move((current_size..connection.queue.size-1), position.to_i)
    end
  end

  def play(position)
    id = id_from_position(position)
    if id
      connection.play(id: id)
    end
  end

  def stop
    connection.stop
  end

  def pause
    connection.pause=(true)
  end

  def unpause
    connection.pause=(false)
  end

  def go_next
    connection.next
  end

  def go_previous
    connection.previous
  end

  def delete(position)
    id = id_from_position(position)
    if id
      connection.delete(id: id)
    end
  end



  private

  def id_from_position(position)
    connection.queue[position].id
  rescue
    nil
  end
end
