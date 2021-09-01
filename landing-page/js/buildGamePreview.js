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
        nameGeneration();
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

function nameGeneration() {
  statusMessage.textContent = 'making up a good name ...';
  // send the topic to a google function for analysis
  var topic = topicField.value;
  request_uri = '/functions/name_generation?topic='+encodeURIComponent(topic);
  fetch(request_uri)
    .then(function (response) {
      if (response.ok) {
        statusMessage.textContent = 'Oooooh, thought of a good name!';
        gameComponentCreation();
      } else {
        throw new Error("nameGeneration() didn't receive a 200 response");
      }
    })
    .catch(function (err) {
      setButtonToFailed();
      statusMessage.textContent = "hmm, '" + topic + "' is too hard to make up a name for!";
      console.log(err);
    });
}

// valid game component names (note that these match the component names
// defined in the BoardGame class - see board_game.rb)
const component_names = [
    'assembly_instructions',
    'game_box',
    'game_instructions',
    'game_board',
    'game_pieces',
    'game_money',
    'question_cards',
    'chance_cards'
  ];

function gameComponentCreation(){
  statusMessage.textContent = 'making game components ...';

  // initiate previews for all components
  componentPreviewPromiseArray = [];
  component_names.forEach((component_name) => { 
    componentPreviewPromiseArray.push(previewGameComponent(component_name));
  });
  // show the 'done' message when done
  Promise.all(componentPreviewPromiseArray)
  .then((values) => {
    getAndShowPdfDownloadLink();
  });
}

function previewGameComponent(component, page = 1){
  // validate component name
  var topic = topicField.value;
  if (typeof(component) !== 'string' || !component_names.includes(component)) {
    throw 'component must be type String and one of '+component_names.join(', ');
  }
  // prepare the preview request uri
  request_uri = '/functions/preview_component?topic='+encodeURIComponent(topic)+
    '&component='+encodeURIComponent(component)+
    '&page='+page;
  // update the component's preview element
  document.getElementById(component).classList.add("loading");
  // send the topic and component to a google function to generate a preview
  // return this promise
  return fetch(request_uri)
    .then((response)=>{
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
        document.getElementById(component).classList.add("failed"); 
        throw new Error("the request to generate a preview of '"+component+"' didn't receive a 200 response");
      }
    })
    .then((blob)=>{
      // add an img element to this component's preview container div,
      // and update it with the received preview image
      document.getElementById(component)
        .appendChild(document.createElement('img'))
        .src = URL.createObjectURL(blob);
    })
    .catch(function (err) {
      setButtonToFailed();
      console.log(err);
    });
}

function clearPreviewArea(){
  // for each child of element with id preview-area
  Array.from(
    document.getElementById('preview-area').children
  ).forEach((item) => {
    // remove the img element inside the div
    while (item.firstChild) {
      item.removeChild(item.lastChild);
    }
    // remove class loading, succeeded and failed
    item.classList.remove('loading', 'succeeded', 'failed');
  });
}

function getAndShowPdfDownloadLink(){
  statusMessage.textContent = 'putting it all together ...';
  // send the topic to a google function for analysis
  var topic = topicField.value;
  request_uri = '/functions/get_pdf_download_link?topic='+encodeURIComponent(topic);
  fetch(request_uri)
    .then(function (response) {
      if (response.ok) {
        return response.text();
      } else {
        throw new Error("get_pdf_download_link() didn't receive a 200 response");
      }
    })
    .then((download_url_string)=>{
      statusMessage.textContent = '';
      unlockTopicInput();
      setButtonToDone(download_url_string);
    })
    .catch(function (err) {
      setButtonToFailed();
      statusMessage.textContent = "hmm, '" + topic + "' cannot be put into a single PDF for some reason!";
      console.log(err);
    });
}

