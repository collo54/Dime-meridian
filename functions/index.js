/**
 * Import function triggers from their respective submodules:
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions/v2");
const {onRequest, onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
// const logger = require("firebase-functions/logger");
const {BigQuery} = require("@google-cloud/bigquery");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

// --- CONFIGURATION ---

// Initialize BigQuery for project Dime-meridian
const bigquery = new BigQuery({projectId: "dime-meridian"});
// Initialize Firestore
const db = getFirestore();

// Define Secrets
const revenueCatSecret = defineSecret("REVENUECAT_WEBHOOK_SECRET");
const elevenLabsApiKey = defineSecret("ELEVENLABS_API_KEY");

// Global Options
setGlobalOptions({maxInstances: 10});

// --- FUNCTIONS ---


/**
 * 1. RevenueCat Webhook
 * Ingests subscription events into BigQuery AND Firestore
 */
exports.revenueCatWebhook = onRequest(
    {
      secrets: [revenueCatSecret],
      region: "us-central1",
    },
    async (req, res) => {
    // 1. Security Check
      const expectedToken = revenueCatSecret.value();
      const receivedToken = req.headers.authorization;

      // --- DEBUG LOGS (Remove after fixing) ---
      console.log(`Expected (Secret Manager): "${expectedToken}"`);
      console.log(`Received (Header): "${receivedToken}"`);
      // ----------------------------------------

      if (!receivedToken || receivedToken.trim() !== expectedToken.trim()) {
        console.warn("Unauthorized webhook attempt");
        return res.status(401).send("Unauthorized");
      }

      try {
        const {event} = req.body;
        if (!event) return res.status(400).send("No event data");

        // 2. Prepare Data for BigQuery
        // Convert timestamp safely to ISO string for BigQuery
        const eventDate = new Date(event.event_timestamp_ms).toISOString();

        const bigQueryRow = {
          event_id: event.id,
          user_id: event.app_user_id,
          product_id: event.product_id,
          amount_usd: event.price || event.price_in_usd || 0.0,
          store: event.store,
          type: event.type,
          timestamp: bigquery.datetime(eventDate),
        };

        // 3. Prepare Data for Firestore
        const firestoreDoc = {
          eventId: event.id,
          userId: event.app_user_id,
          productId: event.product_id,
          amountUsd: event.price || event.price_in_usd || 0.0,
          store: event.store,
          type: event.type,
          rawEvent: event, // Saving raw event is useful for future debugging
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
          eventTimestamp: admin.firestore.Timestamp.fromMillis(event.event_timestamp_ms),
        };

        console.log(`Ingesting event: ${event.type} for ${event.price_in_usd}`);

        // 4. Write to BigQuery and Firestore in parallel
        await Promise.all([
        // Insert into BigQuery
          bigquery
              .dataset("analytics")
              .table("revenue_events")
              .insert([bigQueryRow]),

          // Insert into Firestore (using event.id as doc ID for idempotency)
          db.collection("RevenuecatEvents")
              .doc(event.id)
              .set(firestoreDoc, {merge: true}),
        ]);

        return res.status(200).send("Ingested into BigQuery and Firestore");
      } catch (error) {
        console.error("Error processing webhook:", error);
        return res.status(500).send("Internal Server Error");
      }
    },
);

/**
 * 2. Get ElevenLabs Agent Signed URL
 * Called from Flutter to get a secure WebSocket URL for the Conversational AI
 */
exports.getAgentSignedUrl = onCall(
    {
      secrets: [elevenLabsApiKey],
      region: "us-central1",
    },
    async (request) => {
    // 1. Verify user is authenticated
      if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "User must be logged in.",
        );
      }

      // REPLACE THIS WITH YOUR ACTUAL AGENT ID
      const AGENT_ID = "agent_3901kdqcb4v7fkaaawjhtwqkt84v";

      // Access the secret value
      const apiKey = elevenLabsApiKey.value();

      try {
      // 2. Request signed URL from ElevenLabs
        const response = await axios.get(
            `https://api.elevenlabs.io/v1/convai/conversation/get_signed_url?agent_id=${AGENT_ID}`,
            {
              headers: {
                "xi-api-key": apiKey,
              },
            },
        );

        // 3. Return the secure wss:// URL to the client
        return {signedUrl: response.data.signed_url};
      } catch (error) {
      // console.error("Error fetching signed URL:", error?.response?.data || error.message);
      // Check if response exists, then check if data exists
        const errorData = (error.response && error.response.data) ? error.response.data : error.message;
        console.error("Error fetching signed URL:", errorData);
        throw new HttpsError("internal", "Failed to connect to AI agent.");
      }
    },
);

/**
 * 2. Get ElevenLabs Agent Signed URL
 * Called from Flutter to get a secure WebSocket URL for the Conversational AI
 */
exports.getAgentSignedUrlSubscriptionAgent = onCall(
    {
      secrets: [elevenLabsApiKey],
      region: "us-central1",
    },
    async (request) => {
    // 1. Verify user is authenticated
      if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "User must be logged in.",
        );
      }

      // REPLACE THIS WITH YOUR ACTUAL AGENT ID
      const AGENT_ID = "agent_4001kd4s66yqeajamancdw77zsh6";

      // Access the secret value
      const apiKey = elevenLabsApiKey.value();

      try {
      // 2. Request signed URL from ElevenLabs
        const response = await axios.get(
            `https://api.elevenlabs.io/v1/convai/conversation/get_signed_url?agent_id=${AGENT_ID}`,
            {
              headers: {
                "xi-api-key": apiKey,
              },
            },
        );

        // 3. Return the secure wss:// URL to the client
        return {signedUrl: response.data.signed_url};
      } catch (error) {
      // console.error("Error fetching signed URL:", error?.response?.data || error.message);
      // Check if response exists, then check if data exists
        const errorData = (error.response && error.response.data) ? error.response.data : error.message;
        console.error("Error fetching signed URL:", errorData);
        throw new HttpsError("internal", "Failed to connect to AI agent.");
      }
    },
);


/**
 * Executes a dynamic SQL query generated by Gemini.
 * CAUTION: In production, ensure strict IAM roles or read-only permissions
 * for the service account running this function to prevent SQL injection damage.
 */
exports.runDynamicBigQuery = onCall(
    {region: "us-central1"},
    async (request) => {
    // 1. Get the SQL query generated by Gemini
      const sqlQuery = request.data.query;

      if (!sqlQuery) {
        throw new HttpsError("invalid-argument", "No SQL query provided");
      }

      console.log(`Executing AI Generated Query: ${sqlQuery}`);

      try {
      // 2. Execute against BigQuery
        const options = {
          query: sqlQuery,
          // Ensure we are in the right location
          location: "us-central1",
        };

        const [rows] = await bigquery.query(options);

        // 3. Return results to Flutter
        // Convert Date objects to strings to ensure JSON serialization works
        return {
          data: JSON.parse(JSON.stringify(rows)),
        };
      } catch (error) {
        console.error("BigQuery Error:", error);
        // Return the error message so Gemini knows it wrote bad SQL and can retry
        return {error: error.message};
      }
    },
);

