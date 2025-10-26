// Cloudflare Worker using Firebase Cloud Messaging HTTP v1 API
// Uses a Google Service Account to obtain an OAuth2 access token and then
// calls the FCM v1 endpoint: https://fcm.googleapis.com/v1/projects/{projectId}/messages:send

export interface Env {
  // Secrets to set via `wrangler secret put <NAME>`
  SA_CLIENT_EMAIL: string; // Service account client_email
  SA_PRIVATE_KEY: string;  // Service account private_key (PEM, as provided in JSON)
  PROJECT_ID: string;      // Firebase/GCP project id
  API_KEY: string;         // Shared key to protect this endpoint from abuse
}

const OAUTH_TOKEN_URL = 'https://oauth2.googleapis.com/token';
const OAUTH_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';

function base64UrlEncode(data: ArrayBuffer | string): string {
  let bytes: Uint8Array;
  if (typeof data === 'string') {
    bytes = new TextEncoder().encode(data);
  } else {
    bytes = new Uint8Array(data);
  }
  let b64 = btoa(String.fromCharCode(...bytes));
  return b64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
}

function normalizePem(pem: string): string {
  // If the secret was pasted from JSON, it may contain literal "\n" sequences.
  // Convert them to real newlines first.
  let fixed = pem.replace(/\\n/g, '\n').trim();
  // Ensure header/footer are on their own lines (helps when pasted as a single line)
  fixed = fixed
    .replace(/-----BEGIN PRIVATE KEY-----/g, '-----BEGIN PRIVATE KEY-----\n')
    .replace(/-----END PRIVATE KEY-----/g, '\n-----END PRIVATE KEY-----');
  return fixed;
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const normalized = normalizePem(pem);
  const b64 = normalized
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s+/g, '');
  const raw = atob(b64);
  const buffer = new ArrayBuffer(raw.length);
  const view = new Uint8Array(buffer);
  for (let i = 0; i < raw.length; i++) view[i] = raw.charCodeAt(i);
  return buffer;
}

async function getAccessToken(env: Env): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claims = {
    iss: env.SA_CLIENT_EMAIL,
    scope: OAUTH_SCOPE,
    aud: OAUTH_TOKEN_URL,
    iat: now,
    exp: now + 3600,
  };

  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedClaims = base64UrlEncode(JSON.stringify(claims));
  const signingInput = `${encodedHeader}.${encodedClaims}`;

  const keyData = pemToArrayBuffer(env.SA_PRIVATE_KEY);
  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    keyData,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  );
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(signingInput)
  );
  const jwt = `${signingInput}.${base64UrlEncode(signature)}`;

  const params = new URLSearchParams();
  params.set('grant_type', 'urn:ietf:params:oauth:grant-type:jwt-bearer');
  params.set('assertion', jwt);

  const res = await fetch(OAUTH_TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: params,
  });
  if (!res.ok) {
    const t = await res.text();
    throw new Error(`OAuth token error ${res.status}: ${t}`);
  }
  const json = await res.json();
  return json.access_token as string;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method !== 'POST') {
      return new Response('Method Not Allowed', { status: 405 });
    }

    const apiKey = request.headers.get('X-Api-Key') || '';
    if (!env.API_KEY || apiKey !== env.API_KEY) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    let body: any;
    try {
      body = await request.json();
    } catch (e) {
      return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const to = body.to as string | undefined;
    if (!to) {
      return new Response(JSON.stringify({ error: 'Missing "to" (FCM token)' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const notification = body.notification || {};
    const data = body.data || {};

    // Obtain access token using service account
    let accessToken: string;
    try {
      accessToken = await getAccessToken(env);
    } catch (e: any) {
      return new Response(
        JSON.stringify({ error: 'oauth_token_error', message: e?.message ?? String(e) }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const url = `https://fcm.googleapis.com/v1/projects/${env.PROJECT_ID}/messages:send`;
    const payload = {
      message: {
        token: to,
        notification,
        data,
        android: {
          priority: 'HIGH',
          notification: {
            // Ensure Android routes system notifications to the app's channel when present
            channel_id: 'emergency_channel',
          },
        },
      },
    };

    const fcmResp = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${accessToken}`,
      },
      body: JSON.stringify(payload),
    });

    const text = await fcmResp.text();
    return new Response(text, {
      status: fcmResp.status,
      headers: { 'Content-Type': 'application/json' },
    });
  },
};
