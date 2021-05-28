// Create an instance of the Stripe object with your publishable API key
const stripe = Stripe('pk_test_7tyV8ujlWRgxEbCtm8n1G4wb');
const checkoutButton = document.getElementById('checkout-button');

checkoutButton.addEventListener('click', function() {
  // TO-DO: send a request to 


  // Create a new Checkout Session using the Google Cloud Function `create_stripe_checkout_session`
  request_uri = '/functions/checkout?topic='+encodeURIComponent(topicField.value);
  fetch(request_uri, {method: 'POST'})
    .then(function(response) {
      return response.json();
    })
    .then(function(session) {
      return stripe.redirectToCheckout({ sessionId: session.id });
    })
    .then(function(result) {
      // If `redirectToCheckout` fails due to a browser or network
      // error, you should display the localized error message to your
      // customer using `error.message`.
      if (result.error) {
        alert(result.error.message);
      }
    })
    .catch(function(error) {
      console.error('Error:', error);
    });
});