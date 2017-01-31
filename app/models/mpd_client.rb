class MpdClient

  attr_accessor :connection

  def self.client
    mpdclient = new
    mpdclient.connection = MPD.new('localhost', 6600, {:callbacks => true})
    mpdclient.connect
    mpdclient
  end

  def connect
    unless connection.connected?
      connection.connect
      connection.consume = true
      connection.random = false
      connection.repeat = false
      connection.single = false

      connection.on :songid do |s|
        current_song_changes(s)
      end

      connection.on :nextsongid do |s|
        next_song_changed(s)
      end
    end
  end

  def current_song_changed_callback(s)
    Rails.logger.debug "Current song changed #{s}"
  end

  def next_song_changed_callback(s)
    Rails.logger.debug "Next song changed: #{s}"
  end

  ## return song
  def index_file(file)
    music_index = music_file_index(file)
    Song.update(music_index.to_h)
  end

  ## return array of songs
  def index_playlist_file(file)
    playlist = []
    connection.send_command(:listplaylistinfo, file).each_with_index do |song, i|
      playlist << Song.update(song.merge( file_index: i ))
    end
    playlist
  end

  ##
  ## modify queue (current playlist)
  ##

  def queue_file(file, position)
    queue_audiofile(file, position)
  rescue MPD::NotFound
    queue_playlist(file, nil, position)
  end

  ## add single file to position in queue
  def queue_audiofile(file, position)
    ## load song to queue
    connection.addid(file, position.to_i)
    # index_file(file)
  end

  ## add playlist to queue in chunks
  def queue_playlist(file, playlist_range, queue_position, chunk_size=10)
    current_size = connection.queue.size
    ## load playlist to queue
    playlist = MPD::Playlist.new(connection, file)

    ## load as range in chunks
    playlist_range.each_slice(chunk_size) do |slice|
      playlist.load(slice.first..slice.last)

      previous_size = current_size
      current_size = connection.queue.size

      connection.move((previous_size..current_size-1), queue_position.to_i)
      queue_position += chunk_size
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

  def music_file_index(file)
    existing_index = connection.songs(file).first
    Rails.logger.debug "Found index - got song"
    existing_index
  rescue
    Rails.logger.debug "Not found - indexing"
    connection.update(file)
    existing_index = connection.songs(file).first
  end
end
