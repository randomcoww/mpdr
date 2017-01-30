class Content
  include Elasticsearch::Persistence::Model

  # attribute :path, String, mapping: { index: 'not_analyzed' }
  attribute :name, String
  attribute :directory, Boolean
  attribute :mtime, Integer
  attribute :children, String, default: [], mapping: { index: 'not_analyzed' }

  ## path is relative to mpd music path
  def self.reindex(path, recursive=false)
    Dir.chdir(Rails.application.config.mpd_mount_path)

    if File.file?(path)
      return reindex_file(path)

    elsif File.directory?(path)
      return reindex_directory(path, recursive)
    end
    nil
  end

  def self.reindex_file(path)
    content = get_or_create(path)
    content.name = File.basename(path)
    content.directory = false
    content.children = []
    content.save
    content
  end

  def self.reindex_directory(path, recursive=false)
    content = get_or_create(path)
    content.name = File.basename(path)
    content.directory = true
    content.children = []

    # full_path = File.join(Rails.application.config.mpd_mount_path, path)
    Dir.entries(path).each do |e|
      case e
      when '.', '..'
        next
      end

      content.children << e
      if recursive
        child = Content.reindex(File.join(path, e), true)
      end
    end
    content.save
    content
  end

  def self.get_or_create(id)
    find(id)
  rescue
    content = new
    content[:id] = id
    content
  end
end
