// Game-preview building functions
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
  statusMessage.textContent = 'word-counting ...';
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

const valid_components = [
    'game-box',
    'game-money',
    'game-instructions',
    'assembly-instructions',
    'game-board',
    'question-cards',
    'chance-cards',
    'game-piece-1',
    'game-piece-2',
    'game-piece-3',
    'game-piece-4',
    'game-piece-5',
    'game-piece-6',
    'game-piece-7',
    'game-piece-8'
  ];

function gameComponentCreation(){
  statusMessage.textContent = 'making game components ...';
  valid_components.forEach(previewGameComponent);
}

function previewGameComponent(component){
  var topic = topicField.value;
  if (typeof(component) !== 'string' || !valid_components.includes(component)) {
    throw 'component must be type String and one of '+valid_components.join(', ');
  }
  // send the topic and component to a google function to generate a preview
  request_uri = '/functions/preview_component?topic='+encodeURIComponent(topic)+'&component='+encodeURIComponent(component);
  document.getElementById(component).classList.add("loading"); 
  fetch(request_uri)
    .then(function (response) {
      if (response.ok) {
        document.getElementById(component).classList.add("succeeded"); 
      } else {
        document.getElementById(component).classList.add("failed"); 
        throw new Error("the request to generate a preview of '"+component+"' didn't receive a 200 response");
      }
    })
    .catch(function (err) {
      setButtonToFailed();
      statusMessage.textContent = "uh-oh, there was a problem creating one of the game components!";
      console.log(err);
    });
}