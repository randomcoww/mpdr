class Song
  include Elasticsearch::Persistence::Model

  attribute :date, DateTime
  attribute :albumartist, String
  attribute :album, String
  attribute :track, Integer
  attribute :title, String
  attribute :artist, String
  attribute :genre, String
  attribute :lastmodified, DateTime, mapping: { index: 'not_analyzed' }

  def self.update(c)
    song = get_or_create(c[:file])

    mtime = c['last-modified'.to_sym]
    mtime = mtime.last if mtime.is_a?(Array)

    if mtime.to_i > song.lastmodified.to_i
      song.lastmodified = mtime.to_i
      c.each do |k, v|
        song[k] = v if song.respond_to?(k)
      end

      song.save
    end
    song
  end

  def self.get_or_create(id)
    find(id)
  rescue
    c = new
    c[:id] = id
    c[:lastmodified] = 0
    c
  end
end
