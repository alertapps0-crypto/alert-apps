export interface Env {
  FCM_SERVER_KEY: string; // Cloudflare secret
  API_KEY: string;        // Cloudflare secret for app authentication
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

    const fcmPayload = {
      to,
      notification,
      data,
      priority: 'high',
    };

    const fcmResp = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `key=${env.FCM_SERVER_KEY}`,
      },
      body: JSON.stringify(fcmPayload),
    });

    const text = await fcmResp.text();

    return new Response(text, {
      status: fcmResp.status,
      headers: { 'Content-Type': 'application/json' },
    });
  },
};
