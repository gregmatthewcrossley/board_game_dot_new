// makeButtonConfig.js
// Adds some triggers and events to the "make it" button

// keep the 'state' of the makeButton matched to the topicField
new MutationObserver(function(mutations) {
  makeButton.dataset.state = topicField.dataset.state;
}).observe(
  topicField, 
  { 
    attributes: true, 
    attributeFilter: ['data-state'] 
  }
);

// 'Make' button
makeButton.addEventListener('click', function() {
  if (makeButton.dataset.state = 'ready') {
    // Style changes
    lockTopicInput();
    setButtonToWorking();
    showCancelMakeButton();
    // Game building functions
    buildGame();
    // Style changes

  }
});

// Game building functions
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
        debugger;
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
  // send the topic to a google function to verify its existance
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
  // send the topic to a google function to verify its existance
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
  // send the topic to a google function to verify its existance
  var topic = topicField.value;
  request_uri = '/functions/topic_analysis?topic='+encodeURIComponent(topic);
  fetch(request_uri)
    .then(function (response) {
      if (response.ok) {
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

function gameComponentCreation() {
  statusMessage.textContent = 'creating game components ...';
  // send the topic to a google function to verify its existance
  var topic = topicField.value;
  request_uri = '/functions/topic_analysis?topic='+encodeURIComponent(topic);
  fetch(request_uri)
    .then(function (response) {
      if (response.ok) {
        // preview the image
      } else {
        throw new Error("gameComponentCreation() didn't receive a 200 response");
      }
    })
    .catch(function (err) {
      setButtonToFailed();
      statusMessage.textContent = "uh-oh, there was a problem creating ###!";
      console.log(err);
    });
}

// 'Cancel' button
cancelMakeButton.addEventListener('click', function() {
  hideCancelMakeButton();
  unlockTopicInput();
  setButtonToReady();
  topicRefresh.click();
});




// Style Functions
function setButtonToWorking() {
  makeButton.dataset.state = 'working';
}

function showCancelMakeButton(){
  cancelMakeButton.setAttribute('style', 'display:initial');
  statusMessage.setAttribute('style', 'display:initial');
}

function hideCancelMakeButton(){
  cancelMakeButton.setAttribute('style', 'display:none');
  statusMessage.setAttribute('style', 'display:none');
  statusMessage.textContent = '';
}

function setButtonToFailed(){
  makeButton.dataset.state = 'failed';
}

function setButtonToReady(){
  makeButton.dataset.state = 'ready';
}