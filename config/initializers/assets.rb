# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
Rails.application.config.assets.precompile += %w( admin.css )
Rails.application.config.assets.precompile += %w( admin.js )

Rails.application.config.assets.precompile += %w( static_pages.css )
Rails.application.config.assets.precompile += %w( static_pages.js )

Rails.application.config.assets.precompile += %w( summernote.css )
Rails.application.config.assets.precompile += %w( summernote.min.js )

Rails.application.config.assets.precompile += %w( bootstrap-datetimepicker.min.css )
Rails.application.config.assets.precompile += %w( bootstrap-datetimepicker-custom.js )

Rails.application.config.assets.precompile += %w( ekko-lightbox.min.css )
Rails.application.config.assets.precompile += %w( ekko-lightbox.min.js )

Rails.application.config.assets.precompile += %w( parsley-custom.js )
Rails.application.config.assets.precompile += %w( Chart.min.js )
