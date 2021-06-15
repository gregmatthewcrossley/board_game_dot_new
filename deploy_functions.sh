#!/bin/zsh

echo "Deploying boardgame.new's functions to Google Cloud Functions"
echo

gcloud functions deploy preview \
    --project=pure-lantern-313313 \
    --runtime=ruby27 \
    --trigger-http \
    --allow-unauthenticated \
    --timeout=540s \
    --security-level=secure-always \
    --source=/Users/gmc/Code/board_game_dot_new/ \
    --entry-point=generate_preview_content \
    --env-vars-file .secrets.yaml &

gcloud functions deploy checkout \
    --project=pure-lantern-313313 \
    --runtime=ruby27 \
    --trigger-http \
    --allow-unauthenticated \
    --timeout=540s \
    --security-level=secure-always \
    --source=/Users/gmc/Code/board_game_dot_new/ \
    --entry-point=create_stripe_checkout_session \
    --env-vars-file .secrets.yaml &

gcloud functions deploy checkout_complete \
    --project=pure-lantern-313313 \
    --runtime=ruby27 \
    --trigger-http \
    --allow-unauthenticated \
    --timeout=540s \
    --security-level=secure-always \
    --source=/Users/gmc/Code/board_game_dot_new/ \
    --entry-point=show_checkout_complete_page \
    --env-vars-file .secrets.yaml &

gcloud functions deploy download \
    --project=pure-lantern-313313 \
    --runtime=ruby27 \
    --memory=8192MB \
    --trigger-http \
    --allow-unauthenticated \
    --timeout=540s \
    --security-level=secure-always \
    --source=/Users/gmc/Code/board_game_dot_new/ \
    --entry-point=retrieve_game_pdf \
    --env-vars-file .secrets.yaml &

wait

echo
echo "... done!"
echo

