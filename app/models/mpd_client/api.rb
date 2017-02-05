class MpdClient::Api < MpdClient

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

  def current_song_changed_callback(s)
    Rails.logger.debug "Current song changed #{s}"
  end

  def next_song_changed_callback(s)
    Rails.logger.debug "Next song changed: #{s}"
  end


  def get_indexed_content(c)
    position = c[:pos]
    if c.has_key?(:file)
      begin
        c = Song.find(c[:file])
      rescue
        index = Song.update(c)
        c = index if !index.nil?
      end
    end
    c[:pos] = position if !position.nil?
    c
  end

  def get_database_path(path, start_index, end_index)
    start_index = (start_index || 0).to_i
    end_index = (end_index || -1).to_i

    content = path_info(path)
    content = [content] unless content.is_a?(Array)
    content = content[start_index..end_index]

    content.each_with_index do |c, i|
      content[i] = get_indexed_content(c)
    end
    content
  end

  def get_queue(start_index, end_index)
    start_index = (start_index || 0).to_i
    end_index = (end_index || -1).to_i

    content = connection.send_command(:playlistinfo)
    content = content[start_index..end_index]

    content.each_with_index do |c, i|
      content[i] = get_indexed_content(c)
    end
    content
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
