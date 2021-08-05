// Game_preview building functions
function buildGame() {
  topicExistanceCheck();
}

function topicExistanceCheck() {
  statusMessage.textContent = 'looking up ...';
  // send the topic to a google function to verify its existance
  var topic = topicField.value;
  request_uri = '/functions/topic_existence_check?topic='+encodeURIComponent(topic);
  fetch(request_uri)
    .then(function (response) {
      if (response.ok) {
        topicWordCoundCheck();
      } else {
        throw new Error("topicExistanceCheck() didn't receive a 200 response");
      }
    })
    .catch(function (err) {
      setButtonToFailed();
      statusMessage.textContent = "hmm, '" + topic + "' is a bit too obscure!";
      console.log(err);
    });
}

function topicWordCoundCheck() {
  statusMessage.textContent = 'counting words ...';
  // send the topic to a google function to verify there is enough written content to analyse
  var topic = topicField.value;
  request_uri = '/functions/topic_word_count_check?topic='+encodeURIComponent(topic);
  fetch(request_uri)
    .then(function (response) {
      if (response.ok) {
        topicImageCheck();
      } else {
        throw new Error("topicWordCoundCheck() didn't receive a 200 response");
      }
    })
    .catch(function (err) {
      setButtonToFailed();
      statusMessage.textContent = "hmm, not enough has been written about '" + topic + "'!";
      console.log(err);
    });
}

function topicImageCheck() {
  statusMessage.textContent = 'looking for pretty pictures ...';
  // send the topic to a google function to verify an image exists for it
  var topic = topicField.value;
  request_uri = '/functions/topic_image_check?topic='+encodeURIComponent(topic);
  fetch(request_uri)
    .then(function (response) {
      if (response.ok) {
        topicAnalysis();
      } else {
        throw new Error("topicImageCheck() didn't receive a 200 response");
      }
    })
    .catch(function (err) {
      setButtonToFailed();
      statusMessage.textContent = "hmm, there aren't any great pictures of '" + topic + "'!";
      console.log(err);
    });
}

function topicAnalysis() {
  statusMessage.textContent = 'analysing ...';
  // send the topic to a google function for analysis
  var topic = topicField.value;
  request_uri = '/functions/topic_analysis?topic='+encodeURIComponent(topic);
  fetch(request_uri)
    .then(function (response) {
      if (response.ok) {
        statusMessage.textContent = 'analysis complete!';
        gameComponentCreation();
      } else {
        throw new Error("topicAnalysis() didn't receive a 200 response");
      }
    })
    .catch(function (err) {
      setButtonToFailed();
      statusMessage.textContent = "hmm, '" + topic + "' is a bit too complex!";
      console.log(err);
    });
}

// valid game component names (note that these match the component names
// defined in the BoardGame class - see board_game.rb)
const valid_components = [
    'game_box',
    'game_money',
    'game_instructions',
    'assembly_instructions',
    'game_board',
    'question_cards',
    'chance_cards',
    'game_pieces'
  ];

function gameComponentCreation(){
  statusMessage.textContent = 'making game components ...';
  valid_components.forEach(previewGameComponent);
  // if (document.getElementsByClassName("example")) {
  //   statusMessage.textContent = "uh_oh, there was a problem creating one of the game components!";
  // } else {
  //   statusMessage.textContent = 'All done!';
  // }
}

function previewGameComponent(component, page = 1){
  var topic = topicField.value;
  if (typeof(component) !== 'string' || !valid_components.includes(component)) {
    throw 'component must be type String and one of '+valid_components.join(', ');
  }
  // send the topic and component to a google function to generate a preview
  request_uri = '/functions/preview_component?topic='+encodeURIComponent(topic)+
    '&component='+encodeURIComponent(component)+
    '&page='+page;
  document.getElementById(component).classList.add("loading"); 
  fetch(request_uri)
    .then((response)=>{
      debugger;
      if (response.ok) {
        // update the preview img element's class to 'succeeded'
        document.getElementById(component).classList.add("succeeded");
        // if there are more pages, recursivly call this function (with this page number plus one)
        if (response.status == 206) { // https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/206
          previewGameComponent(component, page + 1);
        }
        return response.blob();
      } else {
        // update the preview img element's class to 'failed'
        // TO-DO: update this to create elements within a specific container (instead of expecting the elements to already exist)
        document.getElementById(component).classList.add("failed"); 
        throw new Error("the request to generate a preview of '"+component+"' didn't receive a 200 response");
      }
    })
    .then((blob)=>{
      // update the preview box with the received preview image
      document.getElementById(component).src = URL.createObjectURL(blob);
    })
    .catch(function (err) {
      setButtonToFailed();
      console.log(err);
    });
}