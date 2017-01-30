require 'rails_helper'

describe MpdClient do

  let! (:client) { MpdClient.client }

  before :each do
    Song.create_index! force: true
  end



  describe "#client" do
    it "creates a new client" do
      expect(client.connection).to be_a(MPD)
    end
  end


  describe "load and index objects to elasticsearch" do

    after :each do
      client.connection.disconnect
    end

    describe ".index_file" do
      ## expect mpd music path at spec/files/mpd_mount
      let (:song) {
        client.index_file('dir1/test1.mp3')
      }

      it "should be a Song object" do
        expect(song).to be_a(Song)
      end

      it "populates elasticsearch index" do
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

    describe ".index_playlist_file" do
      ## expect mpd music path at spec/files/mpd_mount
      let (:playlist) {
        client.index_playlist_file('dir1/test.cue')
      }

      it "should have multiple items" do
        expect(playlist.length).to be(4)
      end

      it "should be Song objects" do
        playlist.each do |s|
          expect(s).to be_a(Song)
        end
      end

      it "first item should be in elasticsearch" do
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
      end

      it "second item should be in elasticsearch" do
        expect(playlist[1].attributes).to include({
          :id => "dir1/test1.mp3_0.013-0.026",
        })
      end
    end
  end


  describe "manipulating playlist" do
    before :each do
      ## clear the active playlist
      client.connection.clear
    end

    after :each do
      client.connection.disconnect
    end


    describe ".queue_file" do
      context "empty playlist" do
        before :each do
          client.queue_file('dir1/test1.mp3', 0)
        end

        it "queue should be 1 long" do
          expect(client.connection.queue.size).to eq(1)
        end

        it "queue item should be correct entry" do
          expect(client.connection.queue.first.file).to eq('dir1/test1.mp3')
        end
      end
    end


    describe ".play" do
      before :each do
        client.queue_file('dir1/test1.mp3', 0)
        client.queue_file('dir2/test2.mp3', 1)
        client.play(0)
      end

      it "sets current_song" do
        expect(client.connection.current_song.file).to eq('dir1/test1.mp3')
      end
    end


    describe ".delete" do
      before :each do
        client.queue_file('dir1/test1.mp3', 0)
      end

      context "with current_song" do
        context "single file" do
          before :each do
            client.play(0)
            client.delete(0)
          end

          context "first file" do
            it "nulls current song" do
              expect(client.connection.current_song).to eq(nil)
            end

            it "deletes item" do
              expect(client.connection.queue.size).to eq(0)
            end
          end
        end

        context "multiple files" do
          before :each do
            client.queue_file('dir2/test2.mp3', 1)

            client.play(0)
            client.delete(0)
          end

          context "first file" do
            it "goes to next song" do
              expect(client.connection.current_song.file).to eq('dir2/test2.mp3')
            end

            it "deletes item" do
              expect(client.connection.queue.size).to eq(1)
            end
          end

          context "last file" do
            it "deletes item" do
              expect(client.connection.queue.size).to eq(1)
            end
          end
        end
      end
    end


    describe ".queue_playlist" do
      context "empty playlist" do
        before :each do
          client.queue_playlist('dir1/test.cue', 0..2, 0)
        end

        it "queue should be correct length" do
          expect(client.connection.queue.size).to eq(3)
        end

        it "should have correct file entry" do
          expect(client.connection.queue[1].file).to eq('dir1/test1.mp3')
        end

        it "should have correct range" do
          expect(client.connection.queue[1].range).to eq('0.013-0.026')
        end
      end

      context "with existing playlist" do

        shared_context "populated playlist" do
          it "queue should be correct length" do
            expect(client.connection.queue.size).to eq(5)
          end

          it "should have correct file entry" do
            expect(client.connection.queue[2].file).to eq('dir1/test1.mp3')
          end

          it "should have correct range" do
            expect(client.connection.queue[2].range).to eq('0.013-0.026')
          end
        end

        before :each do
          ## existing
          client.queue_file('dir1/test1.mp3', 0)
          client.queue_file('dir2/test2.mp3', 1)
        end

        context "no current_song" do
          before :each do
            ## queue new to position 1
            client.queue_playlist('dir1/test.cue', 0..2, 1)
          end

          it_behaves_like "populated playlist"
        end

        context "with existing current_song" do
          before :each do
            # cause current_song to get populated
            client.play(1)
            client.pause
            ## queue new to position 1
            client.queue_playlist('dir1/test.cue', 0..2, 1)
          end

          it_behaves_like "populated playlist"

          it "current song shoud be last position" do
            expect(client.connection.current_song.pos).to eq(4)
          end
        end
      end
    end
  end
end
