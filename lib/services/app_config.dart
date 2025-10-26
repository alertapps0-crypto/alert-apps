/// App configuration for external FCM sender when staying on Firebase Spark plan.
///
/// 1) If you deploy the provided Cloudflare Worker (external/cloudflare-worker),
///    set [EXTERNAL_FCM_ENDPOINT] to its public URL and [EXTERNAL_FCM_API_KEY]
///    to the same API key you configured as a secret in the worker.
/// 2) Leave these empty to disable the external sender.

const String EXTERNAL_FCM_ENDPOINT = 'https://fcm-sender.alertapps.workers.dev';
const String EXTERNAL_FCM_API_KEY =
    '2EkX74jb0kCZPbf/hKOkgaLfkQaJ5hvxdV9Eanz4skg=';

/// Whether to use the external FCM sender when available.
/// If false or if [EXTERNAL_FCM_ENDPOINT] is empty, the app will not attempt
/// to call an external service and will rely on Firestore-based in-app notifications
/// only (no background push while on Spark plan).
const bool USE_EXTERNAL_FCM_SENDER = true;
