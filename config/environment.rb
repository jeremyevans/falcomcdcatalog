# Load the Rails framework and configure your application.
# You can include your own configuration at the end of this file.
#
# Be sure to restart your webserver when you modify this file.

# The path to the root directory of your application.
RAILS_ROOT = File.join(File.dirname(__FILE__), '..')

# The environment your application is currently running.  Don't set
# this here; put it in your webserver's configuration as the RAILS_ENV
# environment variable instead.
#
# See config/environments/*.rb for environment-specific configuration.
RAILS_ENV  = ENV['RAILS_ENV'] || 'development'


# Load the Rails framework.  Mock classes for testing come first.
ADDITIONAL_LOAD_PATHS = ["#{RAILS_ROOT}/test/mocks/#{RAILS_ENV}"]

# Then model subdirectories.
ADDITIONAL_LOAD_PATHS.concat(Dir["#{RAILS_ROOT}/app/models/[_a-z]*"])
ADDITIONAL_LOAD_PATHS.concat(Dir["#{RAILS_ROOT}/components/[_a-z]*"])

# Followed by the standard includes.
ADDITIONAL_LOAD_PATHS.concat %w(
  app 
  app/models 
  app/controllers 
  app/helpers 
  app/apis 
  components 
  config 
  lib 
  vendor 
  vendor/rails/railties
  vendor/rails/railties/lib
  vendor/rails/actionpack/lib
  vendor/rails/activesupport/lib
  vendor/rails/activerecord/lib
  vendor/rails/actionmailer/lib
  vendor/rails/actionwebservice/lib
).map { |dir| "#{RAILS_ROOT}/#{dir}" }.select { |dir| File.directory?(dir) }

# Prepend to $LOAD_PATH
ADDITIONAL_LOAD_PATHS.reverse.each { |dir| $:.unshift(dir) if File.directory?(dir) }

# Require Rails libraries.
require 'rubygems' unless File.directory?("#{RAILS_ROOT}/vendor/rails")

require 'active_support'
require 'active_record'
require 'action_controller'
require 'action_mailer'
require 'action_web_service'

# Environment-specific configuration.
require_dependency "environments/#{RAILS_ENV}"
ActiveRecord::Base.configurations = File.open("#{RAILS_ROOT}/config/database.yml") { |f| YAML::load(f) }
ActiveRecord::Base.establish_connection


# Configure defaults if the included environment did not.
begin
  RAILS_DEFAULT_LOGGER = Logger.new("#{RAILS_ROOT}/log/#{RAILS_ENV}.log")
  RAILS_DEFAULT_LOGGER.level = (RAILS_ENV == 'production' ? Logger::INFO : Logger::DEBUG)
rescue StandardError
  RAILS_DEFAULT_LOGGER = Logger.new(STDERR)
  RAILS_DEFAULT_LOGGER.level = Logger::WARN
  RAILS_DEFAULT_LOGGER.warn(
    "Rails Error: Unable to access log file. Please ensure that log/#{RAILS_ENV}.log exists and is chmod 0666. " +
    "The log level has been raised to WARN and the output directed to STDERR until the problem is fixed."
  )
end

[ActiveRecord, ActionController, ActionMailer].each { |mod| mod::Base.logger ||= RAILS_DEFAULT_LOGGER }
[ActionController, ActionMailer].each { |mod| mod::Base.template_root ||= "#{RAILS_ROOT}/app/views/" }

# Set up routes.
ActionController::Routing::Routes.reload

Controllers = Dependencies::LoadingModule.root(
  File.join(RAILS_ROOT, 'app', 'controllers'),
  File.join(RAILS_ROOT, 'components')
)

# Include your app's configuration here:
ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS = false

module ActiveRecord
  class Base
    @scaffold_fields = nil
    def self.scaffold_fields
      @scaffold_fields ||= column_names
    end
  
    @scaffold_select_order = nil
    def self.scaffold_select_order
      @scaffold_select_order
    end
  
    def scaffold_name
      self[:name] || id
    end
  end

  module ConnectionAdapters
    class PostgreSQLAdapter
      def columns(table_name, name = nil)
        $ARColumns ||= {}
        $ARColumns[table_name] ||= column_definitions(table_name).collect do |name, type, default|
          Column.new(name, default_value(default), translate_field_type(type))
        end
      end
    end
  end

  module Associations
    class HasAndBelongsToManyAssociation
      def insert_record(record)
        if record.new_record?
          return false unless record.save
        end

        if @options[:insert_sql]
          @owner.connection.execute(interpolate_sql(@options[:insert_sql], record))
        else
          columns = @owner.connection.columns(@join_table, "#{@join_table} Columns")

          attributes = columns.inject({}) do |attributes, column|
            case column.name
              when @association_class_primary_key_name
                attributes[column.name] = @owner.quoted_id
              when @association_foreign_key
                attributes[column.name] = record.quoted_id
              else
                value = record[column.name]
                attributes[column.name] = value unless value.nil?
            end
            attributes
          end
          attributes.delete('id')
          sql =
            "INSERT INTO #{@join_table} (#{@owner.send(:quoted_column_names, attributes).join(', ')}) " +
            "VALUES (#{attributes.values.collect { |value| @owner.send(:quote, value) }.join(', ')})"

          @owner.connection.execute(sql)
        end
        
        return true
      end
    end
  end
end

module ActionController
  class Base
    @@scaffold_template_dir = "#{RAILS_ROOT}/lib/scaffolds/" 
    cattr_accessor :scaffold_template_dir
  
    private
    # User modifiable scaffold templates are good!
    def scaffold_path2(template_name)
      File.join(@@scaffold_template_dir, template_name + ".rhtml")
    end
  
    # Slightly modified version of render_scaffold
    def render_habtm_scaffold(action = "habtm")
      if template_exists?("#{self.class.controller_path}/#{action}")
        render_action(action)
      else
        add_instance_variables_to_assigns
        @content_for_layout = @template.render_file(scaffold_path2(action), false)
        self.active_layout ? render_file(self.active_layout, "200 OK", true) : render_file(scaffold_path2("layout"))
      end
    end
  
    # Used in functions created by scaffold_habtm
    # There's probably a better way to do this
    def multiple_select_ids(arr)
      arr.collect{|x| x.to_i}.delete_if{|x| x == 0}
    end
  end
  
  module Caching
    module Pages
      @@page_cache_directory = '/var/www/htdocs'
    end
  end

  module Scaffolding
    module ClassMethods
      def scaffold_habtm(singular_class, many_class, both_ways = true)
        singular_name = singular_class.name
        many_class_name = many_class.name
        many_name = Inflector.underscore(Inflector.pluralize(many_class.name))
        reflection = singular_class.reflect_on_association(many_name.to_sym)
        return false if reflection.nil? or reflection.macro != :has_and_belongs_to_many
        foreign_key = reflection.options[:foreign_key] || singular_class.table_name.classify.foreign_key
        association_foreign_key = reflection.options[:association_foreign_key] || many_class.table_name.classify.foreign_key
        join_table = reflection.options[:join_table] || ( singular_name < many_class_name ? '#{singular_name}_#{many_class_name}' : '#{many_class_name}_#{singular_name}')
        suffix = "_#{Inflector.underscore(singular_name)}_#{many_name}" 
        module_eval <<-"end_eval", __FILE__, __LINE__
          def edit#{suffix}
            @singular_name = "#{singular_name}" 
            @many_name = "#{many_name.gsub('_',' ')}" 
            @singular_object = #{singular_name}.find(@params['id'])
            @items_to_remove = #{many_class_name}.find(:all, :conditions=>["id IN (SELECT #{association_foreign_key} FROM #{join_table} WHERE #{join_table}.#{foreign_key} = ?)", @params['id'].to_i], :order=>"#{many_class.scaffold_select_order}").collect{|item| [item.scaffold_name, item.id]}
            @items_to_add = #{many_class_name}.find(:all, :conditions=>["id NOT IN (SELECT #{association_foreign_key} FROM #{join_table} WHERE #{join_table}.#{foreign_key} = ?)", @params['id'].to_i], :order=>"#{many_class.scaffold_select_order}").collect{|item| [item.scaffold_name, item.id]}
            @scaffold_update_page = "update#{suffix}" 
            render_habtm_scaffold
          end
    
          def update#{suffix}
            singular_item = #{singular_name}.find(@params['id'])
            singular_item.#{many_name}.push(#{many_class_name}.find(multiple_select_ids(@params['add']))) if @params['add']
            singular_item.#{many_name}.delete(#{many_class_name}.find(multiple_select_ids(@params['remove']))) if @params['remove']
            redirect_to(:action=>"edit#{suffix}", :id=>@params['id'])
          end
        end_eval
        both_ways ? scaffold_habtm(many_class, singular_class, false) : true
      end
    end
  end
end

require 'action_view'
module ActionView
  module Helpers
    module ActiveRecordHelper
      def all_input_tags(record, record_name, options)
        input_block = options[:input_block] || default_input_block
        associations = {}
        record.class.reflect_on_all_associations.each {|a| associations[a.name.to_s] = a}
        record.class.scaffold_fields.collect{ |field|
          if record.attributes.include? field
            input_block.call(record_name, record.column_for_attribute(field)) 
          elsif associations.has_key? field
            input_block.call(record_name, associations[field]) 
          else ''
          end
        }.join("\n")
      end
    
      def default_input_block
        Proc.new do |record, column| 
          if column.class.name =~ /Reflection/
            if column.macro == :belongs_to
              "<p><label for='#{record}_#{column.options[:foreign_key] || column.klass.table_name.classify.foreign_key}'>#{column.klass.name}:</label><br />#{input(record, column.name)}</p>\n\n" 
            end
          else
            "<p><label for='#{record}_#{column.name}'>#{column.human_name}:</label><br />#{input(record, column.name)}</p>\n\n" 
          end  
        end
      end
    end

    class InstanceTag #:nodoc:
      alias_method :to_tag_old, :to_tag
      def to_tag(options = {})
        if column_type ==:text
          options[:size] = 80
          to_input_field_tag("text", options)
        elsif column_type == :select
          options[:include_blank] = true
          to_association_select_tag(options)
        else to_tag_old(options)
        end
      end
    
      def column_type
        object.attributes.include?(@method_name) ? object.send(:column_for_attribute, @method_name).type : :select
      end
    
      def to_association_select_tag(options)
        reflection = object.class.reflect_on_association @method_name.to_sym
        @method_name = reflection.options[:foreign_key] || reflection.klass.table_name.classify.foreign_key
        to_collection_select_tag(reflection.klass.find(:all, :order => reflection.klass.scaffold_select_order, :conditions=>reflection.options[:conditions]), :id, :scaffold_name, options, {})
      end
    end
  end
end