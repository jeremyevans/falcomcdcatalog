GEM_RAILS_VERSION = '2.1.0'
require File.join(File.dirname(__FILE__), 'boot')

$:.unshift "/home/jeremy/sequel/sequel/lib"
$:.unshift "/home/jeremy/sequel/sequel_core/lib"
require 'sequel'

Rails::Initializer.run do |config|
  config.frameworks -= [ :active_record, :active_resource, :action_mailer ]
  config.action_controller.default_charset = 'ISO-8859-1'
end

ActionController::Base.param_parsers.delete(Mime::XML)
if ADMIN
  require 'scaffolding_extensions'
  ScaffoldingExtensions::MetaModel::SCAFFOLD_OPTIONS[:text_to_string] = true
  ScaffoldingExtensions::MetaModel::SCAFFOLD_OPTIONS[:auto_complete].merge!({:sql_name=>'name', :text_field_options=>{:size=>80}, :search_operator=>'ILIKE', :results_limit=>15, :phrase_modifier=>:to_s})
  ScaffoldingExtensions::MetaModel::SCAFFOLD_OPTIONS[:habtm_ajax] = true
else
  module ActionController
    class AbstractRequest
      def relative_url_root
        nil
      end
    end
    module Routing
      class RouteSet
        def recognize!(request)
          string_path = request.request_uri.split('?')[0]
          string_path.chomp! if string_path[0] == ?/
          path = string_path.split '/'
          path.shift

          hash = recognize_path(path)
          return recognition_failed(request) unless hash && hash['controller']

          controller = hash['controller']
          hash['controller'] = controller.controller_path
          request.path_parameters = hash
          controller.new
        end
      end
    end
  end
end
