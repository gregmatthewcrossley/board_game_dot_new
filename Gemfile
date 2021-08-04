# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# for loading all ruby class files
gem 'require_all'

# debugging
gem 'pry'
gem 'terminal-table'

# for core functionality
gem 'wikipedia-client', require: 'wikipedia' # for retreiving Wikipedia articles
gem 'google-cloud-language', require: 'google/cloud/language' # for analyzing text
gem 'date' # for generating plausable date substitutes
gem 'i18n' # for activesupport-inflector
gem 'activesupport-inflector', require: 'active_support/inflector' # for pluralization / singularization of nouns
gem 'prawn' # for PDF generation

# for Google Cloud Functions, Storage and Error Reporting
gem "functions_framework", "~> 0.9"
gem "google-cloud-storage", require: "google/cloud/storage"
gem "stackdriver", require: "google/cloud/error_reporting"

# for image downloading and processing
gem "down", "~> 5.0"
gem "mini_magick"

# for payment processing
gem 'stripe'

# for testing
group :test do
  gem 'minitest'
end