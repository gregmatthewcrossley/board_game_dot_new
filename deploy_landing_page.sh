#!/bin/zsh

echo "Deploying boardgame.new's landing page to Google Cloud Storage ..."
echo

# echo "Removing old files ..."
# gsutil rm gs://board-game-dot-new/*.*

# copy all HTML, JS and CSS files, and set them to `puclic`
gsutil -m -h Cache-Control:no-store cp -a public-read -r \
  landing-page/*.html \
  landing-page/*.js \
  landing-page/*.css \
  landing-page/*.png \
  landing-page/*.ico \
  landing-page/*.svg \
  landing-page/*.webmanifest \
  gs://board-game-dot-new

# invalidate the Google's CDN cache
# echo "Invalidating CDN cache (may take 4 minutes) ..."
# gcloud compute url-maps invalidate-cdn-cache board-game-dot-new-load-balancer --path "/*"

# # set the default pages for Google Cloud Storage web access (index and 404)
echo "Setting the default web pages' file names ..."
gsutil web set -m index.html -e 404.html gs://board-game-dot-new

echo
echo "All files deployed to Google Cloud Storage"
