class Content
  include Elasticsearch::Persistence::Model

  attribute :name, String
  attribute :directory, Boolean
  attribute :mtime, Integer
  attribute :children, String, default: [], mapping: { index: 'not_analyzed' }

  def self.reindex(opts)
    path = opts[:path].to_s
    recursive = !!opts[:recursive]
    content = nil

    if File.file?(path)
      content = get_or_create(path)
      content.name = File.basename(path)
      content.directory = false
      content.save

    elsif File.directory?(path)
      content = get_or_create(path)
      content.name = File.basename(path)
      content.directory = true

      Dir.entries(path).each do |e|
        case e
        when '.', '..'
          next
        end

        full_path = File.join(path, e)
        content.children << e

        if recursive
          child = Content.get_or_create(full_path)
        end
      end
      content.save
    end
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
