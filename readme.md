# Boardgame.new

To use locally, via the command line:
```bash
pry -r './board_game.rb' -e 'BoardGame.cli'
```

To run tests locally:
```bash
ruby board_game_test.rb
```

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/Users/gmc/Code/21dots/google_application_credentials.json"
```

### To run a function locally
```bash
bundle exec functions-framework-ruby --target generate_preview_content
```

### To deploy a function
```bash
gcloud functions deploy 'Generate Preview Content' \
    --project=pure-lantern-313313 \
    --runtime=ruby27 \
    --trigger-http \
    --entry-point=generate_preview_content
```


## Infrastructure
For the most part, this app uses Google Cloud services. 

The domain, `boardgame.new`, is registered using Google Domains. A SSL certificate exists for this domain (covering `boardgamenew` and `www.boardgame.new`, the latter of which isn't actually used for anything!)

The IP address, `34.102.189.92`, is reserved by Google.

This IP address points to an HTTPS load balancer, provided by google. The load balancer matches two types of paths to two different backends:
1) Traffic sent to `boardgame.new/*` is sent to the landing page (a static HTML page stored publicly on Google Cloud Storage)
2) Traffic sent to `boardgame.new/functions/*` is sent to Google Cloud Functions.

The landing page, as mentioned above, is a collection of static HTML, JS and CSS files, stored on a Google Cloud Storage bucket. Each file is individually set to be publicly readable.

The backend logic (ie the Ruby code that generates the game content) is broken down into a few Ruby functions, running on Google Cloud Functions.

## App Dependencies
The core functionality of the app relies on two APIs - Wikipedia (for raw text and image content) and Google Natural Language (for parsing and contextualizing the text content).

