const topicForm = document.getElementById('topic-form')
const topicField = document.getElementById('topic-field')

topicForm.addEventListener( 
  "submit", 
  function(e){ 
    var xhr = new XMLHttpRequest();
    xhr.withCredentials = true;
    xhr.open('GET', '/functions/preview?'+encodeURIComponent(topicField.value));
    xhr.onload = function() {
      if (xhr.status === 200) {
        alert('Game name is ' + xhr.responseText);
      }
      else {
        alert('Request failed.  Returned status of ' + xhr.status);
      }
    };
    xhr.send();

    e.preventDefault();
  }
);


