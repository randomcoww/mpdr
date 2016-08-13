class MpdClient

  attr_accessor :connection

  def self.client
    mpdclient = new
    mpdclient.connection = MPD.new('localhost', 6600, {:callbacks => true})
    mpdclient.connect
    mpdclient
  end

  def connect
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


  def current_playlist
    'default'
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
    connection.send_command(:listplaylistinfo, file).each do |song|
      playlist << Song.update(song)
    end
    playlist
  end

  def queue_file(file, position)
    index_file(file)
    ## load song to queue
    connection.addid(file, position.to_i)
    Playlist.update(current_playlist, connection.queue)
  end

  def queue_playlist(file, range)
    index_playlist_file(file)
    ## load playlist to queue
    playlist = MPD::Playlist.new(connection, file)
    playlist.load(range)
    Playlist.update(current_playlist, connection.queue)
  end

  def move(id, offset)
    connection.move({id: id}, offset)
    Playlist.update(current_playlist, connection.queue)
  end

  def delete(id)
    connection.delete(id: id)
    Playlist.update(current_playlist, connection.queue)
  end

  def current_queue
    playlist = []
    connection.queue.each do |song|
      playlist << Song.update(song.to_h)
    end
    playlist
  end

  private

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
