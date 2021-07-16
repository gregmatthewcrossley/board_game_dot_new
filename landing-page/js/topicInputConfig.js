// topicInputConfig.js
// Handles retrieivng a list of pre-vetted topics, 
// populating the input field with a random topic, 
// configuring and initializing the autocomplete library
// and other behavior

fetch('/functions/topics')
  .then(function (response) {
    return response.json();
  })
  .then(function (responseJson) {
    vettedTopics = responseJson.vetted_topics;
  })
  .then(function(){
    // define the refreshTopic function (updates the input field to a randon topic)
    function refreshTopic() {
      document.getElementById('topic-field').value = vettedTopics[Math.floor(Math.random() * vettedTopics.length)];
    }
    // refresh on click of the refresh button
    document.getElementById('topic-refresh').addEventListener('click', function() {
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
    console.log("error configuring vettedTopics", err);
  });

