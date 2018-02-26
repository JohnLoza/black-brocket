source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

ruby '2.4.3'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.4'
# Use mysql as the database for Active Record
gem 'mysql2', '>= 0.3.18', '< 0.5'
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
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# CarrierWave provides a simple and extremely flexible way to upload files from Ruby applications. #
gem 'carrierwave', '~> 1.2.1'
# Use SCSS for stylesheets
gem 'sass-rails'
# MiniMagick gives you access to all the command line options ImageMagick has (it's used by carrierwave too, for image manipulation) #
gem 'mini_magick', '~> 4.3.6'
# WillPaginate is a pagination library #
gem 'will_paginate', '~> 3.0.7'
# Integrates the Twitter Bootstrap pagination component with the will_paginate pagination gem. #
gem 'will_paginate-bootstrap', '~> 1.0.1'
# rqrcode-with-patches for qr code generation #
gem 'rqrcode-with-patches', '~> 0.5.4'
