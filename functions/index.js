const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");
const { onCall } = require("firebase-functions/v2/https");
/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const axios = require("axios");

// Proxy function to fetch Places securely
exports.getPlacesAutocomplete = onCall(
  { cors: true }, // Enables CORS for this function
  async (request) => {
    const input = request.data.input;
    const apiKey = "AIzaSyB87_uR_oZbh504BGowBOPR6Y_nQDo2LeQ"; // Use a secure Server Key, not the browser one

    if (!input) return { predictions: [] };

    try {
      const url = `https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${encodeURIComponent(input)}&key=${apiKey}&components=country:gh`;
      const response = await axios.get(url);
      return response.data;
    } catch (error) {
      throw new HttpsError("internal", "Failed to fetch places");
    }
  }
);

// Proxy function to get Place Details (Lat/Lng)
exports.getPlaceDetails = onCall(
  { cors: true },
  async (request) => {
    const placeId = request.data.placeId;
    const apiKey = "AIzaSyB87_uR_oZbh504BGowBOPR6Y_nQDo2LeQ";

    try {
      const url = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&fields=geometry&key=${apiKey}`;
      const response = await axios.get(url);
      return response.data;
    } catch (error) {
      throw new HttpsError("internal", "Failed to fetch details");
    }
  }
);