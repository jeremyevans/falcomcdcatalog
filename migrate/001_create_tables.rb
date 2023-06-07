# frozen_string_literal: true
class CreateFalcomCDCatalogTables < Sequel::Migration
  def up
    create_table :albums do
      primary_key :id
      String :sortname
      String :picture
      String :info
      Integer :numdiscs
      String :fullname
    end
    create_table :albuminfos do
      primary_key :id
      foreign_key :albumid, :albums
      Integer :discnumber
      Integer :starttrack
      Integer :endtrack
      String :info
    end
    create_table :artists do
      primary_key :id
      String :name
      String :jname
    end
    create_table :discnames do
      primary_key :id
      foreign_key :albumid, :albums
      Integer :number
      String :name
    end
    create_table :series do
      primary_key :id
      String :name
    end
    create_table :games do
      primary_key :id
      foreign_key :seriesid, :series
      String :name
      String :jname
    end
    create_table :languages do
      primary_key :id
      String :name
    end
    create_table :lyricsongs do
      primary_key :id
      String :jsongname
      String :rsongname
      foreign_key :composer_id, :artists
      foreign_key :arranger_id, :artists
      foreign_key :lyricist_id, :artists
      foreign_key :vocalist_id, :artists
      String :joriginalsongname
    end
    create_table :lyricverses do
      primary_key :id
      foreign_key :lyricsongid, :lyricsongs
      foreign_key :languageid, :languages
      Integer :number
      String :verse
    end
    create_table :mediatypes do
      primary_key :id
      String :name
    end
    create_table :publishers do
      primary_key :id
      String :name
    end
    create_table :media do
      primary_key :id
      foreign_key :albumid, :albums
      foreign_key :mediatypeid, :mediatypes
      String :catalognumber
      Integer :price
      Date :publicationdate
      Float :ordernum
      foreign_key :publisherid, :publishers
    end
    create_table :songs do
      primary_key :id
      String :name
      foreign_key :gameid, :games
      foreign_key :lyricid, :lyricsongs, :index=>true
      foreign_key :arrangementof, :songs
      index :name,  :unique=>true
    end
    create_table :tracks do
      primary_key :id
      foreign_key :albumid, :albums
      Integer :discnumber
      Integer :number
      foreign_key :songid, :songs
      index [:albumid, :discnumber, :number], :unique=>true
    end
    create_table :seriesalbums do
      foreign_key :seriesid, :series
      foreign_key :albumid, :albums
    end
    create_table :gamealbums do
      foreign_key :gameid, :games
      foreign_key :albumid, :albums
    end
  end

  def down
    drop_table(:gamealbums, :seriesalbums, :tracks, :songs, :media, :publishers, :mediatypes, :lyricverses, :lyricsongs, :languages, :games, :series, :discnames, :artists, :albuminfos, :albums)
  end
end
