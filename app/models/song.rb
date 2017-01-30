class Song
  include Elasticsearch::Persistence::Model

  attribute :file, String, mapping: { index: 'not_analyzed' }
  attribute :range, String, mapping: { index: 'not_analyzed' }
  attribute :date, DateTime
  attribute :albumartist, String
  attribute :album, String
  attribute :track, Integer
  attribute :title, String
  attribute :artist, String
  attribute :genre, String
  attribute :playlist_index, Integer, mapping: { index: 'not_analyzed' }

  def self.update(opts)
    id = opts[:file]
    unless opts[:range].to_s.blank?
      id += "_#{opts[:range].to_s}"
    end

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
