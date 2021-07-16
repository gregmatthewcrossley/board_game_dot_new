// makeButtonConfig.js
// Adds some triggers and events to the "make it" button

// DOM elements
const makeButton = document.getElementById('make-button');
const topicField = document.getElementById('topic-field');
const statusMessage = document.getElementById('status');
const cancelMakeButton = document.getElementById('cancel-make-button');
const previewArea = document.getElementById('preview');
const callToActionArea = document.getElementById('call-to-action');

makeButton.addEventListener('click', function() {
  
  styleButtonAsWorking();

  topicExistanceCheck(topicField.value);

  // 
  // fetch(request_uri)
  //   .then(function (response) {
  //     return response.json();
  //   })
  //   .then(function (board_game_preview) {
  //     // add the generated game's name to the preview area
  //     previewArea.textContent = board_game_preview.name;
  //     // show the call to action (stripe checkout session creation form)
  //     callToActionArea.setAttribute('style', 'display:block');
  //   })
  //   .catch(function (err) {
  //       console.log("Something went wrong!", err);
  //   });
});

function styleButtonAsWorking() {

  // restyle the button on click
  makeButton.classList.add('working');
  makeButton.classList.remove('failed');

  // lock the input field
  topicField.setAttribute('disabled', 'true');

  // show a status text under the spinner
  statusMessage.textContent = 'researching ...';
  statusMessage.setAttribute('style', 'display:block');
  
  // show the cancel button
  cancelMakeButton.setAttribute('style', 'display:inline');

  // re-hide the call to action area, if shown
  callToActionArea.removeAttribute('style');
}

function topicExistanceCheck(topic) {
  statusMessage.textContent = 'looking up ...';
  // send the topic to a google function to verify its existance
  request_uri = '/functions/topic_existence_check?topic='+encodeURIComponent(topic);
  fetch(request_uri)
    .then(function (response) {
      return response.json();
    })
    // .then(function (board_game_preview) {
    //   // add the generated game's name to the preview area
    //   previewArea.textContent = board_game_preview.name;
    //   // show the call to action (stripe checkout session creation form)
    //   callToActionArea.setAttribute('style', 'display:block');
    // })
    .catch(function (err) {
      statusMessage.textContent = "hmm, '" + topic + "' is a bit too obscure!";
      styleButtonAsFailed();
      document.getElementById('topic-field').value = "";
    });
}


// Cancel
cancelMakeButton.addEventListener('click', function() {
  styleButtonAsDefault();
  document.getElementById('topic-refresh').click();
});

// cancelMakeButton.addEventListener('click', function() {
//   styleButtonAsDefault();
// });

function styleButtonAsFailed(){
  // restyle the button
  makeButton.classList.remove('working');
  makeButton.classList.add('failed');

  // unlock the input field
  topicField.removeAttribute('disabled');
  
  // hide the cancel button
  cancelMakeButton.setAttribute('style', 'display:none');
}

function styleButtonAsDefault(){
  // restyle the button
  makeButton.classList.remove('working');
  makeButton.classList.remove('failed');

  // unlock the input field
  topicField.removeAttribute('disabled');

  // hide the status text
  statusMessage.setAttribute('style', 'display:none');
  
  // hide the cancel button
  cancelMakeButton.setAttribute('style', 'display:none');
}