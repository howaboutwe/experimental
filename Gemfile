source 'https://rubygems.org/'
gemspec

gem 'sqlite3'
gem 'timecop'

group :test do
  gem 'capybara'
  gem 'factory_girl'
  gem 'shoulda-matchers'
end

group :test, :development do
  gem 'rails', ENV['EXPERIMENTAL_RAILS']
  gem 'pry'
  gem 'ritual'
  gem 'rspec'
  gem 'rspec-rails'
end
