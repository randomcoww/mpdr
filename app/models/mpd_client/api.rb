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
    playlist_id = c[:id]

    if c.has_key?(:file)
      begin
        c = Song.find(c[:file])
      rescue
        index = Song.update(c)
        c = index if !index.nil?
      end
    end
    c[:playlist_id] = playlist_id
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

    content = connection.send_command(:playlistinfo, (start_index..end_index))

    content.each_with_index do |c, i|
      content[i] = get_indexed_content(c)
    end
    content
  end

  def length
    connection.status[:playlistlength]
  end

  ## add single file to position in queue
  def add_file(path, position=nil)
    c = path_info(path)
    connection.addid(c[:file], position)
  end

  ## needed for directories
  def add_path(path, position=nil)
    c = path_info(path)
    length_before = length
    connection.send_command(:add, path)
    ## move files to desired position
    move(length_before, length-1, position) if !position.nil?
  end

  def play(playlist_id)
    connection.send_command(:playid, playlist_id)
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

  def move(start_index, end_index, to_index)
    connection.send_command(:move, (start_index.to_i..end_index.to_i), to_index.to_i)
  end

  def remove(start_index, end_index)
    connection.send_command(:delete, (start_index.to_i..end_index.to_i))
  end
end
