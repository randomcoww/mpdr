class Content
  include Elasticsearch::Persistence::Model

  attribute :name, String
  attribute :directory, Boolean
  attribute :mtime, Integer
  attribute :children, String, default: [], mapping: { index: 'not_analyzed' }

  def reindex(recursive=false)
    if File.file?(id)
      self.name = File.basename(id)
      self.mtime = File.mtime(id)
      self.directory = false
      self.save

    elsif File.directory?(id)
      self.name = File.basename(id)
      self.mtime = File.mtime(id)
      self.directory = true

      Dir.entries(id).each do |e|
        case e
        when '.', '..'
          next
        end

        full_path = File.join(id, e)
        self.children << e

        child = Content.get_or_create(full_path)
        if recursive
          child.reindex(true)
        else
          child.save
        end
      end
      self.save
    end
    self
  end

  def self.get_or_create(id)
    find(id)
  rescue
    file = new
    file[:id] = id
    file
  end
end
