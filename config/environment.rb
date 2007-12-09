GEM_RAILS_VERSION = '2.0.1'
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  config.frameworks -= [ :active_resource, :action_mailer ]
  config.action_controller.default_charset = 'ISO-8859-1'
end

ActionController::Base.param_parsers.delete(Mime::XML)
ActiveRecord::Base.scaffold_convert_text_to_string = true
ActiveRecord::Base.scaffold_auto_complete_default_options.merge!({:sql_name=>'name', :text_field_options=>{:size=>80}, :search_operator=>'ILIKE', :results_limit=>15, :phrase_modifier=>:to_s})
ActiveRecord::Base.scaffold_habtm_with_ajax_default = true
