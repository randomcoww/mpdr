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
    ## load song to queue
    connection.addid(file, position.to_i)
    # index_file(file)
  end

  def queue_playlist(file, playlist_positions, queue_position)
    current_size = connection.queue.size
    ## load playlist to queue
    playlist = MPD::Playlist.new(connection, file)

    ## playlist supports loading range but want to load individually.
    ## if loaded as range, single delete call will remove all of it.
    playlist_positions.each do |e|
      playlist.load(e)
    end

    ## playlist items always loads at end
    ## move range of new items into position
    connection.move((current_size..connection.queue.size-1), queue_position.to_i)
    # index_playlist_file(file)
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
