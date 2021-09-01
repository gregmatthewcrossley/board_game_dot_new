#!/bin/zsh

echo "Deploying boardgame.new's functions to Google Cloud Functions"
echo

gcloud functions deploy topics \
    --project=pure-lantern-313313 \
    --runtime=ruby27 \
    --trigger-http \
    --allow-unauthenticated \
    --timeout=540s \
    --security-level=secure-always \
    --source=/Users/gmc/Code/board_game_dot_new/ \
    --entry-point=retrieve_vetted_topics \
    --env-vars-file .secrets.yaml &

gcloud functions deploy topic_existence_check \
    --project=pure-lantern-313313 \
    --runtime=ruby27 \
    --trigger-http \
    --allow-unauthenticated \
    --timeout=540s \
    --security-level=secure-always \
    --source=/Users/gmc/Code/board_game_dot_new/ \
    --entry-point=topic_existence_check \
    --env-vars-file .secrets.yaml &

gcloud functions deploy topic_word_count_check \
    --project=pure-lantern-313313 \
    --runtime=ruby27 \
    --trigger-http \
    --allow-unauthenticated \
    --timeout=540s \
    --security-level=secure-always \
    --source=/Users/gmc/Code/board_game_dot_new/ \
    --entry-point=topic_word_count_check \
    --env-vars-file .secrets.yaml &

gcloud functions deploy topic_image_check \
    --project=pure-lantern-313313 \
    --runtime=ruby27 \
    --trigger-http \
    --allow-unauthenticated \
    --timeout=540s \
    --security-level=secure-always \
    --source=/Users/gmc/Code/board_game_dot_new/ \
    --entry-point=topic_image_check \
    --env-vars-file .secrets.yaml &

gcloud functions deploy topic_analysis \
    --project=pure-lantern-313313 \
    --runtime=ruby27 \
    --trigger-http \
    --allow-unauthenticated \
    --timeout=540s \
    --security-level=secure-always \
    --source=/Users/gmc/Code/board_game_dot_new/ \
    --entry-point=topic_analysis \
    --env-vars-file .secrets.yaml &

gcloud functions deploy name_generation \
    --project=pure-lantern-313313 \
    --runtime=ruby27 \
    --trigger-http \
    --allow-unauthenticated \
    --timeout=540s \
    --security-level=secure-always \
    --source=/Users/gmc/Code/board_game_dot_new/ \
    --entry-point=name_generation \
    --env-vars-file .secrets.yaml &

gcloud functions deploy preview_component \
    --project=pure-lantern-313313 \
    --runtime=ruby27 \
    --trigger-http \
    --allow-unauthenticated \
    --timeout=540s \
    --security-level=secure-always \
    --source=/Users/gmc/Code/board_game_dot_new/ \
    --entry-point=preview_component \
    --env-vars-file .secrets.yaml &

gcloud functions deploy get_pdf_download_link \
    --project=pure-lantern-313313 \
    --runtime=ruby27 \
    --trigger-http \
    --allow-unauthenticated \
    --timeout=540s \
    --security-level=secure-always \
    --source=/Users/gmc/Code/board_game_dot_new/ \
    --entry-point=get_pdf_download_link \
    --env-vars-file .secrets.yaml &



# gcloud functions deploy preview \
#     --project=pure-lantern-313313 \
#     --runtime=ruby27 \
#     --trigger-http \
#     --allow-unauthenticated \
#     --timeout=540s \
#     --security-level=secure-always \
#     --source=/Users/gmc/Code/board_game_dot_new/ \
#     --entry-point=generate_preview_content \
#     --env-vars-file .secrets.yaml &

# gcloud functions deploy checkout \
#     --project=pure-lantern-313313 \
#     --runtime=ruby27 \
#     --trigger-http \
#     --allow-unauthenticated \
#     --timeout=540s \
#     --security-level=secure-always \
#     --source=/Users/gmc/Code/board_game_dot_new/ \
#     --entry-point=create_stripe_checkout_session \
#     --env-vars-file .secrets.yaml &

# gcloud functions deploy checkout_complete \
#     --project=pure-lantern-313313 \
#     --runtime=ruby27 \
#     --trigger-http \
#     --allow-unauthenticated \
#     --timeout=540s \
#     --security-level=secure-always \
#     --source=/Users/gmc/Code/board_game_dot_new/ \
#     --entry-point=show_checkout_complete_page \
#     --env-vars-file .secrets.yaml &

# gcloud functions deploy download \
#     --project=pure-lantern-313313 \
#     --runtime=ruby27 \
#     --trigger-http \
#     --allow-unauthenticated \
#     --timeout=540s \
#     --security-level=secure-always \
#     --source=/Users/gmc/Code/board_game_dot_new/ \
#     --entry-point=retrieve_game_pdf \
#     --env-vars-file .secrets.yaml &

wait

echo
echo "... done!"
echo

