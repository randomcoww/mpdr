require 'rails_helper'

describe MpdClient do

  let! (:client) { MpdClient.client }

  before :each do
    Song.create_index! force: true
    Playlist.create_index! force: true
    ActivePlaylist.create_index! force: true
  end

  describe "#client" do
    it "creates a new client" do
      expect(client.connection).to be_a(MPD)
    end
  end

  describe ".index_file" do
    ## expect mpd music path at spec/files/mpd_mount
    let (:audio_file) { File.join('dir1', 'test1.mp3') }

    it "populates file to MPD and index" do
      song = client.index_file(audio_file)

      expect(song).to be_a(Song)
      expect(song.attributes).to include({
        :album => "test_album1",
        :albumartist => nil,
        :artist => "test_artist1",
        :date => Time.at(30816).to_datetime,
        :file => "dir1/test1.mp3",
        :genre => "test_genre1",
        :id => "dir1/test1.mp3",
        :playlist_index => nil,
        :title => "test_track_title1",
        :track => 1,
      })
    end
  end

  describe ".index_playlist" do
    ## expect mpd music path at spec/files/mpd_mount
    let (:playlist_file) { File.join('dir1', 'test.cue') }

    it "populates playlist to MPD and index" do
      playlist = client.index_playlist_file(playlist_file)

      expect(playlist.length).to be(4)
      expect(playlist.first).to be_a(Song)
      expect(playlist.first.attributes).to include({
        :album => "test_playlist_title",
        :albumartist => "test_performer",
        :artist => "test_artist1",
        :date => Time.at(30816).to_datetime,
        :file => "dir1/test1.mp3",
        :genre => "test_genre1",
        :id => "dir1/test1.mp3_0.000-0.013",
        :playlist_index => nil,
        :range => "0.000-0.013",
        :title => "test1_track1",
        :track => 1,
      })
      expect(playlist[1].attributes).to include({
        :id => "dir1/test1.mp3_0.013-0.026",
      })
    end
  end

  describe ".queue_file" do

    before :each do
      ## clear the active playlist
      client.connection.clear
    end

    context "first entry" do
      let (:audio_file) { File.join('dir1', 'test1.mp3') }

      it "should add and populate active playlist" do
        client.queue_file(audio_file, 0)
        active_playlist = ActivePlaylist.find(client.current_playlist)

        expect(active_playlist.songs.length).to eq(1)
        expect(active_playlist.songs.first).to eq("dir1/test1.mp3")
      end
    end
  end
end
