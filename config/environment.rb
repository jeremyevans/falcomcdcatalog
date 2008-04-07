GEM_RAILS_VERSION = '2.0.2'
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  config.frameworks -= [ :active_resource, :action_mailer ]
  config.action_controller.default_charset = 'ISO-8859-1'
end

ActionController::Base.param_parsers.delete(Mime::XML)
require 'scaffolding_extensions'
ActiveRecord::Base::SCAFFOLD_OPTIONS[:text_to_string] = true
ActiveRecord::Base::SCAFFOLD_OPTIONS[:auto_complete].merge!({:sql_name=>'name', :text_field_options=>{:size=>80}, :search_operator=>'ILIKE', :results_limit=>15, :phrase_modifier=>:to_s})
ActiveRecord::Base::SCAFFOLD_OPTIONS[:habtm_ajax] = true
