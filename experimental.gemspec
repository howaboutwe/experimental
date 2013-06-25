# -*- encoding: utf-8 -*-
$:.unshift File.expand_path('lib', File.dirname(__FILE__))
require 'experimental/version'

Gem::Specification.new do |gem|
  gem.name          = 'experimental'
  gem.version       = Experimental::VERSION
  gem.authors       = ['HowAboutWe.com', 'Rebecca Miller-Webster', 'Bryan Woods']
  gem.email         = ['dev@howaboutwe.com']
  gem.description   = "AB Test framework for Rails"
  gem.summary       = "Adds support for database-backed AB tests in Rails apps"
  gem.homepage      = "http://wwww.github.com/howaboutwe/experimental"
  gem.licenses      = ['MIT']

  gem.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.markdown"]
  gem.test_files = Dir["test/**/*"]

  gem.add_dependency "rails", ">= 3.1.0"
  gem.add_dependency 'jquery-rails'

  gem.add_development_dependency "sqlite3"
  gem.add_development_dependency 'rspec-rails'
  gem.add_development_dependency 'activeadmin'
  gem.add_development_dependency 'sass-rails'
  gem.add_development_dependency 'coffee-rails'
end
