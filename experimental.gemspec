$:.unshift File.expand_path('lib', File.dirname(__FILE__))
require 'experimental/version'

Gem::Specification.new do |gem|
  gem.name          = 'experimental'
  gem.version       = Experimental::VERSION
  gem.authors       = ['HowAboutWe.com', 'Rebecca Miller-Webster', 'Bryan Woods', 'Andrew Watkins', 'George Ogata']
  gem.email         = ['dev@howaboutwe.com']
  gem.description   = "AB Test framework for Rails"
  gem.summary       = "Adds support for database-backed AB tests in Rails apps"
  gem.homepage      = "https://github.com/howaboutwe/experimental"
  gem.licenses      = ['MIT']

  gem.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.markdown"]
  gem.test_files = Dir["test/**/*"]

  gem.add_dependency "rails", "<= 5.0"
  gem.add_dependency 'jquery-rails'
end
