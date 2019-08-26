# Load the Rails application.
require_relative 'application'

# Load rqrcode for qr code creation #
require 'rqrcode'

# Initialize the Rails application.
Rails.application.initialize!
Rails.application.default_url_options = Rails.application.config.action_mailer.default_url_options
