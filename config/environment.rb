# Load the Rails application.
require File.expand_path('../application', __FILE__)

ENV['DEFAULT_DATATABLE_LENGTH'] ||= "10"

# Initialize the Rails application.
Rails.application.initialize!
