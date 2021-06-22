// vettedTopics.js
// Handles retrieivng a list of pre-vetted topics, 
// showing the user a random topic and configuring the autocomplete feature 

// declare an empty topics variable
var topics = [];

// define the refreshTopic function (updates the input field to a randon topic)
function refreshTopic() {
  document.getElementById('topic-field').value = topics[Math.floor(Math.random() * topics.length)];
}

// retrieve list of pre-vetted topics
fetch('/functions/topics')
  .then(function (response) {
    return response.json();
  })
  .then(function (responseJson) {
    topics = topics.concat(responseJson.vetted_topics);
    refreshTopic();
  })
  .catch(function (err) {
    console.log("Something went wrong retrieving vettedTopics!", err);
  });

// refersh on click of the refresh button
document.getElementById('topic-refresh').addEventListener('click', function() {
  refreshTopic();
});