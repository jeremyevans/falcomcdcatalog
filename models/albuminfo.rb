# frozen_string_literal: true
module Falcom
class Albuminfo < Model
  many_to_one :album, :key => :albumid
end
end

# Table: albuminfos
# Columns:
#  id         | integer | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  albumid    | integer |
#  discnumber | integer |
#  starttrack | integer |
#  endtrack   | integer |
#  info       | text    |
# Indexes:
#  albuminfos_pkey | PRIMARY KEY btree (id)
