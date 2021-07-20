// topicInputConfig.js
// Handles retrieivng a list of pre-vetted topics, 
// populating the input field with a random topic, 
// configuring and initializing the autocomplete library
// and other behavior

// a global variable to hold some vetted topics
var vettedTopics = new Array(0);

// add an event listener for when text is entered or removed from the input
topicField.addEventListener('input', function updateValue(e) {
  if (topicField.value == '') {
    topicField.dataset.state = 'blank';
  } else {
    topicField.dataset.state = 'ready';
  }
});

topicField.addEventListener('focus', function() {
  topicField.value = '';
  topicField.dataset.state = 'blank';
});


fetch('/functions/topics')
  .then(function (response) {
    return response.json();
  })
  .then(function (responseJson) {
    vettedTopics = vettedTopics.concat(responseJson.vetted_topics);
  })
  .then(function(){
    // define the refreshTopic function (updates the input field to a randon topic)
    function refreshTopic() {
      topicField.value = vettedTopics[Math.floor(Math.random() * vettedTopics.length)];
      topicField.dataset.state = 'ready';
    }
    // refresh on click of the refresh button
    topicRefresh.addEventListener('click', function() {
      refreshTopic();
    });
    // refresh once after the page loads
    refreshTopic();
    // initialize autoCompleteJS
    const autoCompleteJS = new autoComplete({
      selector: "#topic-field",
      threshold: 4, // start suggesting after n letters
      wrapper: false,
      data: {
        src: vettedTopics
      },
      resultItem: {
        highlight: {
          render: true
        }
      },
      events: { // populate the input field on selection
        input: {
          selection: (event) => {
            const selection = event.detail.selection.value;
              autoCompleteJS.input.value = selection;
            }
          }
        }
    });
  })
  .catch(function (err) {
    console.log("error configuring topic input field", err);
  });

function lockTopicInput(){
  topicField.setAttribute('disabled', 'true');
  topicRefresh.setAttribute('style', 'display:none');
}

function unlockTopicInput(){
  topicField.removeAttribute('disabled');
  topicRefresh.setAttribute('style', 'display:inline');
}
