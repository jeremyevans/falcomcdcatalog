Encoding.default_internal = Encoding.default_external = 'UTF-8' if RUBY_VERSION >= '1.9'
require File.expand_path('../falcomcdcatalog', __FILE__)
run Falcom::App.freeze.app

begin
  require 'refrigerator'
rescue LoadError
else
  require 'tilt/sass' unless File.exist?(File.expand_path('../compiled_assets.json', __FILE__))

  # Don't freeze BasicObject, as tilt template compilation
  # defines and removes methods in BasicObject.
  Refrigerator.freeze_core(:except=>['BasicObject'])
end
