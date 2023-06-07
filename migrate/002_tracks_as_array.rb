# frozen_string_literal: true
Sequel.migration do
  up do
    extension(:pg_array, :pg_row)

    # Just used as a type, not for actual storage
    create_table(:track) do
      Integer :discnumber
      Integer :number
      Integer :songid
    end

    run <<SQL
CREATE OR REPLACE FUNCTION song_ids(track[])
RETURNS integer[]
AS
$$
DECLARE
   tracks ALIAS FOR $1;
   retVal integer[];
BEGIN
   FOR I IN array_lower(tracks, 1)..array_upper(tracks, 1) LOOP
     retVal[I] := (tracks[I]).songid;
   END LOOP;
RETURN retVal;
END;
$$
LANGUAGE plpgsql 
   IMMUTABLE 
RETURNS NULL ON NULL INPUT;
SQL

    add_column :albums, :tracks, 'track[]'

    albums = {}
    self[:tracks].order(:albumid, :discnumber, :number).each do |track|
      (albums[track[:albumid]] ||= []) << Falcom::DB.row_type(:track, [track[:discnumber], track[:number], track[:songid]])
    end
    albums.each do |album_id, tracks|
      self[:albums].where(:id=>album_id).update(:tracks=>Sequel.pg_array(tracks))
    end

    drop_table :tracks
    add_index :albums, Sequel.function(:song_ids, :tracks), :name=>:album_song_ids, :type=>:gin
  end
end
