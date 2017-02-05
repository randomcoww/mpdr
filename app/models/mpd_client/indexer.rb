class MpdClient::Indexer < MpdClient

  def redis
    @redis ||= Redis.new(host: 'localhost', port: 6379)
  end

  ##
  ## incremental index by reading mpd log
  ## parse update log with filebeat into redis and index from redis to elasticsearch
  ##

  def index_incremental
    while true
      item = redis.lpop('music_database')

      if item.nil?
        # Rails.logger.debug("Waiting for content ...")
        # sleep 20
        # next

        # run this as resque schedule
        return
      end

      begin
        item = JSON.parse(item)
        case item['message']

        when / : update: added /
          path = item['message'].gsub(/^.*? : update: added /, '')
          if !path.blank?
            Rails.logger.debug("Add from log #{path}")

            c = path_info(path)
            index_file(c) if c.has_key?(:file)
          end

        when / : update: updating /
          path = item['message'].gsub(/^.*? : update: updating /, '')
          if !path.blank?
            Rails.logger.debug("Update from log #{path}")

            c = path_info(path)
            index_file(c) if c.has_key?(:file)
          end

        when / : update: removing /
          path = item['message'].gsub(/^.*? : update: removing /, '')
          if !path.blank?
            Rails.logger.debug("Delete from log #{path}")

            Song.find(path).destroy rescue true
          end
        end
      rescue
        Rails.logger.warn("Incremental indexer failed to parse item: #{item}")
      end
    end
  end

  ##
  ## full index of db to elasticsearch by recursively reading database
  ## works but slow
  ##

  # def index_database
  #   index_children('')
  # end

  def index_children(path)
    contents = path_info(path)

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
end
