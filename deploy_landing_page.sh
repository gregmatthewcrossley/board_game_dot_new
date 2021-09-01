#!/bin/zsh

echo "Deploying boardgame.new's landing page to Google Cloud Storage ..."
echo

# remove old files
echo "Removing old files ..."
gsutil -m rm gs://board-game-dot-new/*.html 
gsutil -m rm -r gs://board-game-dot-new/css 
gsutil -m rm -r gs://board-game-dot-new/gif 
gsutil -m rm -r gs://board-game-dot-new/icons 
gsutil -m rm -r gs://board-game-dot-new/js 
gsutil -m rm -r gs://board-game-dot-new/svg

# copy all HTML, JS and CSS files, and set them to `public`
gsutil -m -h Cache-Control:no-store cp -a public-read -r landing-page/*.html    gs://board-game-dot-new 
gsutil -m -h Cache-Control:no-store cp -a public-read -r landing-page/css/*.css gs://board-game-dot-new/css 
gsutil -m -h Cache-Control:no-store cp -a public-read -r landing-page/gif/*.gif gs://board-game-dot-new/gif 
gsutil -m -h Cache-Control:no-store cp -a public-read -r landing-page/icons/*.* gs://board-game-dot-new/icons 
gsutil -m -h Cache-Control:no-store cp -a public-read -r landing-page/js/*.js   gs://board-game-dot-new/js 
gsutil -m -h Cache-Control:no-store cp -a public-read -r landing-page/svg/*.svg gs://board-game-dot-new/svg 

# # invalidate the Google's CDN cache
# echo "Invalidating CDN cache (may take 4 minutes) ..."
# gcloud compute url-maps invalidate-cdn-cache board-game-dot-new-load-balancer --path "/*"

# # set the default pages for Google Cloud Storage web access (index and 404)
echo "Setting the default web pages' file names ..."
gsutil web set -m index.html -e 404.html gs://board-game-dot-new

echo
echo "All files deployed to Google Cloud Storage"
