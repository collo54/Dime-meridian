# 💰 Dime Meridian: Your Pocket AI CFO
<img width="1024" height="1024" alt="logo2" src="https://github.com/user-attachments/assets/f519458a-0abf-4c41-8caa-51d37b649442" />

Built with ❤️ for the Google Cloud x ElevenLabs Hackathon
[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?logo=flutter)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Functions%20%26%20Firestore-FFCA28?logo=firebase)](https://firebase.google.com/)
[![Gemini](https://img.shields.io/badge/AI-Gemini%202.5%20Flash-8E75B2?logo=google)](https://deepmind.google/technologies/gemini/)
[![ElevenLabs](https://img.shields.io/badge/Voice-ElevenLabs%20Agents-white)](https://elevenlabs.io/)

> **Testing**
 *Access the app by pressing create account with an anonymous email and password, e.g., Oreyoh30@yahoo.com, yahoopassword, verification not required. My free credits are limited, so the ready apk is provided in the hackathon submit project page for judges, with less than 3k free credits remaining out of 10k. For the public, you can set up your environment as explained below to run your own version of the app with your credentials*

---

## 💡 Inspiration
Being a solo developer or running a startup is a constant balancing act. You're the coder, the marketer, and the CFO all at once. We wanted to build something that gives indie developers the power of a dedicated finance team without the overhead—a tool that lets them track profits on the go, completely hassle-free.

**Dime Meridian** bridges the gap between raw data and human understanding. Instead of staring at complex dashboards, you simply speak to your app. It uses **Gemini** to reason over your financial data and **ElevenLabs** to speak back actionable insights in real-time.

---

## 🚀 Features

*   **🗣️ Voice-First Interface:** Ask questions like *"How much revenue did we make this week?"* and get an instant spoken answer.
*   **🧠 Natural Language to SQL:** Powered by **Gemini 2.5 Flash**, the app translates your voice commands into complex BigQuery SQL queries on the fly.
*   **📄 Document Analysis:** Upload PDF invoices or CSVs; the AI analyzes them and cross-references them with your database.
*   **📊 Real-time Analytics:** Beautiful visualizations using FL Chart real-time changes.
*   **🔒 Secure Infrastructure:** Data is processed via secure Cloud Functions and stored in BigQuery.

---

## 🛠️ Architecture

1.  **Ingestion:** **RevenueCat Webhooks** capture subscription events (Purchases, Renewals) and send them to a **Firebase Cloud Function**, which sanitizes and stores them in **Google BigQuery**.
2.  **Reasoning:** When a user asks a question, the Flutter app uses **Gemini** (via Firebase AI SDK) to generate a SQL query based on the user's intent.
3.  **Execution:** The SQL is executed securely via a Cloud Function against BigQuery.
4.  **Voice Output:** The insight is passed to the **ElevenLabs Conversational Agent** via WebSockets. We implemented a custom **Client-Side WAV Header Generator** in Dart to handle the raw audio stream on Android.

---

## 💻 Developer Setup Guide

If you want to clone and run this project, follow these steps to configure the backend environment.

### 1. Prerequisites
*   Flutter SDK installed.
*   Firebase CLI installed and logged in.
*   A Google Cloud Project with billing enabled (for BigQuery & Secret Manager).
*   Accounts for [RevenueCat](https://www.revenuecat.com/) and [ElevenLabs](https://elevenlabs.io/).

### 2. Firebase & Cloud Functions
Initialize the project and deploy the backend functions.

```bash
# Install dependencies
cd functions
npm install

# Deploy Functions (This creates the BigQuery connector and Webhook listener)
firebase deploy --only functions



We use Google Cloud Secret Manager to keep keys safe. Do not hardcode keys in the app. Run these commands in your terminal:


# RevenueCat Configuration
This acts as a password to ensure only RevenueCat can write to your database.
To start streaming real-time revenue data:

Go to your RevenueCat Dashboard > Project Settings > Integrations.
Select Webhooks.
Webhook URL: Paste your deployed function URL (e.g., https://us-central1-your-project.cloudfunctions.net/revenueCatWebhook).

firebase functions:secrets:set REVENUECAT_WEBHOOK_SECRET
# Enter a strong random string (e.g., "my_super_secret_key_123")

# ElevenLabs Agent Setup
Go to ElevenLabs Agents.
Create a new Agent.
System Prompt: "You are a helpful financial assistant. Summarize the provided data concisely in under 60 words. Do not read raw tables."
Copy the Agent ID, different from the API key(ELEVENLABS_API_KEY) find this in the developer dashboard in Elevenlabs.
Open functions/index.js in this project.
Replace the AGENT_ID variable in the getAgentSignedUrl function with your new ID.
Redeploy functions: firebase deploy --only functions.

# Required for the Voice Agent to authenticate.
firebase functions:secrets:set ELEVENLABS_API_KEY
# Paste your API Key from ElevenLabs Dashboard
