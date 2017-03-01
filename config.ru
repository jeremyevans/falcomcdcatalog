Encoding.default_internal = Encoding.default_external = 'UTF-8' if RUBY_VERSION >= '1.9'
require File.expand_path('../falcomcdcatalog', __FILE__)
use Rack::CommonLogger unless ENV['RACK_ENV'] == 'development'
run Falcom::App.freeze.app
