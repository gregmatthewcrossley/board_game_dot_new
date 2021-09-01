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

// Click the cancel button if the user hits the escape key
document.onkeydown = function(evt) {
  evt = evt || window.event;
  var isEscape = false;
  if ("key" in evt) {
    isEscape = (evt.key === "Escape" || evt.key === "Esc");
  } else {
    isEscape = (evt.keyCode === 27);
  }
  if (isEscape) {
    cancelMakeButton.click();
  }
};

// 'Make' button
makeButton.addEventListener('click', function() {
  if (makeButton.dataset.state == 'ready') {
    // Style changes
    clearPreviewArea();
    lockTopicInput();
    setButtonToWorking();
    showCancelMakeButton();
    // Game building functions
    buildGame();
    // Style changes
  } else if (makeButton.dataset.state == 'done') {
    downloadPdf();
  }
});

// 'Cancel' button
cancelMakeButton.addEventListener('click', function() {
  hideCancelMakeButton();
  unlockTopicInput();
  setButtonToReady();
  topicRefresh.click();
  clearPreviewArea();
});

// Download PDF
function downloadPdf(){
  window.location = makeButton.dataset.pdf_download_url;
}


// Style Functions
function setButtonToReady(){
  makeButton.dataset.state = 'ready';
}

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

function setButtonToDone(url){
  makeButton.dataset.state = 'done';
  makeButton.dataset.pdf_download_url = url;
}
