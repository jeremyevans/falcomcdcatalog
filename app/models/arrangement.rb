class Arrangement < ActiveRecord::Base
  set_table_name 'songs'
  has_many :songs, :foreign_key=>'arrangementof'
  @scaffold_select_order = 'name'
  
  def scaffold_name
    name[0..50]
  end
end
