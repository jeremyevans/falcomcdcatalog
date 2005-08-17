class Song < ActiveRecord::Base
  has_many :tracks, :foreign_key => 'songid'
  belongs_to :game, :foreign_key=>'gameid'
  belongs_to :lyric, :foreign_key=>'lyricid'
  belongs_to :arrangement, :foreign_key=>'arrangementof'
  has_many :arrangements, :foreign_key=>'arrangementof'

  @scaffold_select_order = 'name'
  @scaffold_fields = %w'name game lyric arrangement'
  
  def scaffold_name
    name[0..50]
  end
  
  def merge_into(record)
    raise ActiveRecordError if record.class != self.class
    self.class.reflect_on_all_associations.each do |reflection|
      foreign_key = reflection.options[:foreign_key] || table_name.classify.foreign_key
      sql = case reflection.macro
        when :has_one, :has_many
          "UPDATE #{reflection.klass.table_name} SET #{foreign_key} = #{record.id} WHERE #{foreign_key} = #{id}\n"
        when :has_and_belongs_to_many
          join_table = reflection.options[:join_table] || ( table_name < reflection.klass.table_name ? '#{table_name}_#{reflection.klass.table_name}' : '#{reflection.klass.table_name}_#{table_name}')
          "UPDATE #{join_table} SET #{foreign_key} = #{record.id} WHERE #{foreign_key} = #{id}\n"
      end
      connection.update(sql)
    end
    destroy
    record.reload
  end
end
