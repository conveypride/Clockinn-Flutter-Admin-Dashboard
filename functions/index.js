const { setGlobalOptions } = require("firebase-functions/v2");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require('firebase-admin');
const axios = require('axios');
const { defineSecret } = require('firebase-functions/params');

// 1. Initialize Admin SDK
admin.initializeApp();

// 2. Set Global Options
setGlobalOptions({ maxInstances: 10 });

// 3. Define Secrets
const paystackSecret = defineSecret('PAYSTACK_SECRET');
const googleMapsKey = defineSecret('GOOGLE_MAPS_KEY');

// ==================================================================
// GOOGLE MAPS PROXIES (V2)
// ==================================================================

exports.getPlacesAutocomplete = onCall(
  { 
    cors: true, 
    secrets: [googleMapsKey] 
  }, 
  async (request) => {
    // In V2, data is inside request.data
    const input = request.data.input;
    const apiKey = googleMapsKey.value(); 

    if (!input) return { predictions: [] };

    try {
      const url = `https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${encodeURIComponent(input)}&key=${apiKey}&components=country:gh`;
      const response = await axios.get(url);
      return response.data;
    } catch (error) {
      console.error("Maps Autocomplete Error:", error);
      throw new HttpsError("internal", "Failed to fetch places");
    }
  }
);

exports.getPlaceDetails = onCall(
  { 
    cors: true,
    secrets: [googleMapsKey]
  },
  async (request) => {
    const placeId = request.data.placeId;
    const apiKey = googleMapsKey.value(); 

    try {
      const url = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&fields=geometry&key=${apiKey}`;
      const response = await axios.get(url);
      return response.data;
    } catch (error) {
      console.error("Maps Details Error:", error);
      throw new HttpsError("internal", "Failed to fetch details");
    }
  }
);

// ==================================================================
// USER MANAGEMENT & PAYSTACK (Upgraded to V2)
// ==================================================================

exports.deleteUserAccount = onCall(
  { cors: true }, // Optional: Add CORS if calling from web
  async (request) => {
    // In V2, auth is inside request.auth
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User must be logged in.');
    }

    const uidToDelete = request.data.uid;

    try {
      await admin.auth().deleteUser(uidToDelete);
      return { success: true, message: 'User deleted from Auth.' };
    } catch (error) {
      console.error("Error deleting user:", error);
      throw new HttpsError('internal', 'Could not delete user from Auth.');
    }
  }
);

exports.initializePaystack = onCall(
  { 
    cors: true,
    secrets: [paystackSecret] // Secrets are now passed here in V2
  },
  async (request) => {
    
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be logged in');
  }

  try {
    const secretKey = paystackSecret.value(); 
    const callbackUrl = 'https://clockinngh.com/payment-success'; 

    const response = await axios.post(
      'https://api.paystack.co/transaction/initialize',
      {
        email: request.data.email, // Note: request.data
        amount: request.data.amount, 
        currency: 'GHS',
        callback_url: callbackUrl,
        channels: ['card', 'mobile_money']
      },
      {
        headers: {
          Authorization: `Bearer ${secretKey}`,
          'Content-Type': 'application/json',
        },
      }
    );

    return { 
      url: response.data.data.authorization_url, 
      reference: response.data.data.reference 
    };

  } catch (error) {
    console.error("Paystack Init Error:", error.response ? error.response.data : error.message);
    throw new HttpsError('internal', 'Payment init failed');
  }
});

exports.verifyPaystackPayment = onCall(
  { 
    cors: true,
    secrets: [paystackSecret] 
  },
  async (request) => {
    const reference = request.data.reference;
    const secretKey = paystackSecret.value();

    try {
      const response = await axios.get(
        `https://api.paystack.co/transaction/verify/${reference}`,
        {
          headers: { Authorization: `Bearer ${secretKey}` }
        }
      );

      const data = response.data.data;
      
      // Strict check: Status must be success AND amount must match
      if (data.status === 'success') {
        return { success: true, amount: data.amount };
      }
      return { success: false };

    } catch (error) {
      console.error("Verify Error:", error);
      throw new HttpsError('internal', 'Verification failed');
    }
  }
);