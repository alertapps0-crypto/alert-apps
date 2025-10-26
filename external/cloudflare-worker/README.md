# Cloudflare Worker FCM Sender (Spark plan friendly)

This Worker lets you send Firebase Cloud Messaging (FCM) notifications from your app without using Firebase Cloud Functions (so you can stay on the Firebase Spark plan). You can use either the legacy FCM HTTP API (simple) or the HTTP v1 API (recommended when Legacy is disabled).

## How it works

- Your Flutter app makes a POST request to this Worker URL with:
  - `to` (device FCM token),
  - `notification` (title/body),
  - `data` (custom map).
- The Worker forwards the payload to FCM `https://fcm.googleapis.com/fcm/send` using Authorization header `key=YOUR_SERVER_KEY`.
- The Worker checks a shared header `X-Api-Key` against a secret to prevent abuse.

## Setup

Prerequisites:

- Node.js and npm installed
- Cloudflare account
- Cloudflare Wrangler CLI installed

```powershell
npm install -g wrangler
```

1. Create a new Cloudflare Worker project (or use this folder):

```powershell
cd external/cloudflare-worker
wrangler init --yes
```

This will create a `wrangler.toml` if it doesn't exist.

2. Add the following to `wrangler.toml` (Legacy API variant):

```toml
name = "fcm-sender"
main = "src/index.ts"
compatibility_date = "2024-08-01"
```

3. Set secrets in Cloudflare (Legacy API variant):

- FCM_SERVER_KEY: your Firebase Cloud Messaging server key (Project settings → Cloud Messaging → Cloud Messaging API (Legacy) → Server key)
- API_KEY: a random string you will also set in the Flutter app config

```powershell
wrangler secret put FCM_SERVER_KEY
wrangler secret put API_KEY
```

4. Install dependencies (none needed beyond default for Workers), then publish:

```powershell
wrangler deploy
```

5. Copy the deployed URL and paste it into the Flutter app `EXTERNAL_FCM_ENDPOINT` (in `lib/services/app_config.dart`). Also set `EXTERNAL_FCM_API_KEY` to the same `API_KEY` you set above.

## Request format (from Flutter app)

```json
{
  "to": "DEVICE_FCM_TOKEN",
  "notification": {
    "title": "Emergency Alert from <teacher>",
    "body": "<message>"
  },
  "data": {
    "type": "emergency",
    "teacherName": "...",
    "teacherPhone": "...",
    "notificationId": "...",
    "senderId": "...",
    "recipientIds": ["...", "..."]
  }
}
```

The Flutter code already sends this format if `EXTERNAL_FCM_ENDPOINT` is configured.

## Notes

- If your Firebase Cloud Messaging API (Legacy) is disabled, use the HTTP v1 variant below.
- Do not embed your FCM server key or Service Account private key in the mobile app. Keep them only as Cloudflare Secrets.

---

## HTTP v1 Variant (Recommended when Legacy is disabled)

Use this when the "Cloud Messaging API (Legacy)" is disabled in your Firebase project. The Worker will obtain an OAuth2 access token using a Google Service Account and call the FCM v1 endpoint.

1. Switch `wrangler.toml` to use the v1 worker entry:

```toml
name = "fcm-sender"
main = "src/index_v1.ts"
compatibility_date = "2024-08-01"
```

2. Create a Service Account JSON in Google Cloud Console (IAM & Admin → Service Accounts → Keys) and keep it private. From that JSON, you will need:

- `client_email`
- `private_key`
- `project_id`

3. Store the following secrets in Cloudflare:

```powershell
wrangler secret put SA_CLIENT_EMAIL   # value: client_email from JSON
wrangler secret put SA_PRIVATE_KEY    # value: private_key from JSON (include the BEGIN/END lines)
wrangler secret put PROJECT_ID        # value: project_id
wrangler secret put API_KEY           # same shared key you set in the app
```

4. Deploy the Worker:

```powershell
wrangler deploy
```

5. Configure the Flutter app (`lib/services/app_config.dart`):

- `EXTERNAL_FCM_ENDPOINT` = your Worker URL
- `EXTERNAL_FCM_API_KEY` = same API_KEY secret
- `USE_EXTERNAL_FCM_SENDER` = true

The request body from the app is the same as in the Legacy variant. The v1 worker will translate it to:

```json
{
  "message": {
    "token": "DEVICE_FCM_TOKEN",
    "notification": { "title": "...", "body": "..." },
    "data": { "type": "emergency", ... },
    "android": { "priority": "HIGH" }
  }
}
```

Security tips:

- Never commit the service account JSON to your repo. Only store `client_email` and `private_key` as Cloudflare Secrets.
- Consider validating a Firebase ID token in addition to `X-Api-Key` for stronger protection in production.
