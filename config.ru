Encoding.default_internal = Encoding.default_external = 'UTF-8'
require File.expand_path('../falcomcdcatalog', __FILE__)
run Falcom::App.freeze.app

require 'tilt/sass' unless File.exist?(File.expand_path('../compiled_assets.json', __FILE__))
Tilt.finalize!

begin
  require 'refrigerator'
rescue LoadError
else

  # Don't freeze BasicObject, as tilt template compilation
  # defines and removes methods in BasicObject.
  Refrigerator.freeze_core(:except=>['BasicObject'])
end
