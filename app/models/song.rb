class Song
  include Elasticsearch::Persistence::Model

  attribute :file, String
  attribute :range, String
  attribute :date, String
  attribute :albumartist, String
  attribute :album, String
  attribute :track, Integer
  attribute :title, String
  attribute :artist, String
  attribute :genre, String
  attribute :playlist_index, Integer
  attribute :next, Song
  attribute :prev, Song

  def self.update(opts)
    id = "#{opts[:file]}_#{opts[:playlist_index].to_i}"
    song = get_or_create(id)

    opts.each do |k, v|
      song[k] = v if song.respond_to?(k)
    end

    song.save
    song
  end

  def self.get_or_create(id)
    find(id)
  rescue
    song = new
    song[:id] = id
    song
  end
end
