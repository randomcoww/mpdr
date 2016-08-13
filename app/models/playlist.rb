class Playlist
  include Elasticsearch::Persistence::Model

  attribute :songs, Array[Song]
  attribute :ids, Array[Integer]

  def self.update(id, songs)
    playlist = get_or_create(id)

    playlist[:songs] = []
    playlist[:ids] = []

    songs.each do |s|
      playlist[:songs] << Song.find("#{s.file}_#{s.playlist_index.to_i}")
      playlist[:ids] << s.id
    end

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
