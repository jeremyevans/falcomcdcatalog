class LyricVerse < Sequel::Model(:lyricverses)
  many_to_one :lyric, :key=>:lyricsongid
end

# Table: lyricverses
# Columns:
#  id          | integer | PRIMARY KEY DEFAULT nextval('lyricverses_id_seq'::regclass)
#  lyricsongid | integer |
#  languageid  | integer |
#  number      | integer |
#  verse       | text    |
# Indexes:
#  lyricverses_pkey | PRIMARY KEY btree (id)
