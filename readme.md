# Boardgame.new

## Local Development

### To use board_game_dot_new locally, via the command line:
```bash
cd cli
./run_cli.sh
```

### To run tests locally:
```bash
cd tests
./run_tests.sh
```

### To run a web server locally (for the static HTML etc pages)
```bash
ruby local_server.rb
```
and then in your browser, go to `http://localhost:8000/`

### To run one specific function locally
```bash
bundle exec functions-framework-ruby --target generate_preview_content
```
and then in your browser, go to `http://localhost:8081?topic=Rob+Ford`

### To run a web server and all functions locally (in the background):
```bash
./run_local_servers.sh
```


## Production

### To deploy all functions
```bash
./deploy_functions.sh
```

### To Deploy all front-end code
```bash
./deploy_landing_page.sh
```

To set the Google credential environment
```bash
export GOOGLE_APPLICATION_CREDENTIALS="/Users/gmc/Code/board_game_dot_new/google_application_credentials.json"
```

### To deploy one function
```bash
gcloud functions deploy preview \
    --project=pure-lantern-313313 \
    --runtime=ruby27 \
    --trigger-http \
    --allow-unauthenticated \
    --entry-point=generate_preview_content \
    --env-vars-file .secrets.yaml
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

## GOOGLe API key environment variables
Need to be set locally (ie for CLI or testing) but when run on Google Functions, not neccesary, as they are inferred from the account running the function
