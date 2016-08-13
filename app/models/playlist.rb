class Playlist
  include Elasticsearch::Persistence::Model

  attribute :songs, Array[Song]

  def self.update(id, songs)
    playlist = get_or_create(id)
    playlist[:songs] = songs
    playlist.save
    playlist
  end

  private

  def self.get_or_create(id)
    find(id)
  rescue
    playlist = new
    playlist[:id] = id
    playlist
  end
end
