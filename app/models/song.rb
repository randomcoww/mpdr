class Song
  include Elasticsearch::Persistence::Model

  attribute :file, String
  attribute :date, DateTime
  attribute :albumartist, String
  attribute :album, String
  attribute :track, Integer
  attribute :title, String
  attribute :artist, String
  attribute :genre, String

  def self.update(c)
    song = get_or_create(c[:file])
    c.each do |k, v|
      song[k] = v if song.respond_to?(k)
    end

    song.save
    song
  rescue
    Rails.log.error("Failed to update song from #{c}")
  end

  def self.get_or_create(id)
    find(id)
  rescue
    c = new
    c[:id] = id
    c
  end
end
