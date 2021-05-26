#!/bin/zsh

echo "Deploying boardgame.new's functions to Google Cloud Functions"
echo

gcloud functions deploy preview \
    --project=pure-lantern-313313 \
    --runtime=ruby27 \
    --trigger-http \
    --allow-unauthenticated \
    --entry-point=generate_preview_content &

gcloud functions deploy checkout \
    --project=pure-lantern-313313 \
    --runtime=ruby27 \
    --trigger-http \
    --allow-unauthenticated \
    --entry-point=create_stripe_checkout_session &

gcloud functions deploy make_link \
    --project=pure-lantern-313313 \
    --runtime=ruby27 \
    --trigger-http \
    --allow-unauthenticated \
    --entry-point=generate_game_pdf_download_url &

gcloud functions deploy download \
    --project=pure-lantern-313313 \
    --runtime=ruby27 \
    --trigger-http \
    --allow-unauthenticated \
    --entry-point=retrieve_game_pdf &

wait

echo
echo "... done!"
echo

