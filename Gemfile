source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

ruby '~> 2.3' #tested with 2.5.1

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1' #tested with 5.2.4.3
# Use Puma as the app server
gem 'puma', '~> 3.7'
# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 2.13'
  gem 'selenium-webdriver'
  # Use mysql as the database for Active Record
  gem 'mysql2', '>= 0.3.18', '< 0.5'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'rake', '12.3.2'
end

group :production do
  # Use postgreSQL as the database for Active Record
  gem 'pg'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem 'jquery-rails'
gem 'sass-rails'
gem 'uglifier'

gem 'carrierwave', '~> 1.2.1'
gem 'mini_magick', '~> 4.3.6' # required by carrierwave

gem 'will_paginate'
gem 'will_paginate-bootstrap'

gem 'rqrcode' # qr codes
gem 'barby' # barcodes

gem 'conekta'

#gem 'wicked_pdf' # for pdf rendering
#gem 'wkhtmltopdf-binary'

gem 'bbva', git: "https://github.com/EcommerceBBVA/BBVA-RUBY"
