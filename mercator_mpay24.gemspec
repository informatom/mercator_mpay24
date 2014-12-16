$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "mercator_mpay24/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "mercator_mpay24"
  s.version     = MercatorMpay24::VERSION
  s.authors     = ["Stefan Haslinger"]
  s.email       = ["stefan.haslinger@informatom.com"]
  s.homepage    = "http://mercator.informatom.com"
  s.summary     = "MercatorMpay provides an MPay4 gateway for Mesonic."
  s.description = "MercatorMpay provides an MPay4 gateway for Mesonic."

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.0"
  s.add_dependency 'savon', '~> 2.0'
end