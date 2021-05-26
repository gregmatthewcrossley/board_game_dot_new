// Create an instance of the Stripe object with your publishable API key
var stripe = Stripe('pk_test_7tyV8ujlWRgxEbCtm8n1G4wb');
var checkoutButton = document.getElementById('checkout-button');

checkoutButton.addEventListener('click', function() {
  // Create a new Checkout Session using the Google Cloud Function `create_stripe_checkout_session`
  fetch('/checkout?Rob+Ford', {
    method: 'GET',
  })
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