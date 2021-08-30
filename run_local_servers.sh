#!/bin/zsh

ruby local_server.rb &
bundle exec functions-framework-ruby --port 8001 --target retrieve_vetted_topics GOOGLE_APPLICATION_CREDENTIALS="../google_application_credentials.json" &
bundle exec functions-framework-ruby --port 8001 --target topic_existence_check GOOGLE_APPLICATION_CREDENTIALS="../google_application_credentials.json" &
bundle exec functions-framework-ruby --port 8001 --target topic_word_count_check GOOGLE_APPLICATION_CREDENTIALS="../google_application_credentials.json" &
bundle exec functions-framework-ruby --port 8001 --target topic_image_check GOOGLE_APPLICATION_CREDENTIALS="../google_application_credentials.json" &
bundle exec functions-framework-ruby --port 8001 --target topic_analysis GOOGLE_APPLICATION_CREDENTIALS="../google_application_credentials.json" &
bundle exec functions-framework-ruby --port 8001 --target name_generation GOOGLE_APPLICATION_CREDENTIALS="../google_application_credentials.json" &
bundle exec functions-framework-ruby --port 8001 --target preview_component GOOGLE_APPLICATION_CREDENTIALS="../google_application_credentials.json" 