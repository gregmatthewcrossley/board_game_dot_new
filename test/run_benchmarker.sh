#!/bin/zsh

export GOOGLE_APPLICATION_CREDENTIALS="../google_application_credentials.json" 

pry -r "./benchmarker.rb"
