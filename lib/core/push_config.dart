// lib/core/push_config.dart
//
// Public half of the VAPID keypair used to sign Web Push subscriptions —
// safe to ship in client code (that's the whole point of the
// public/private split; only the private half, held by the
// send-daily-challenge-push Edge Function, can actually sign a push).
const String kVapidPublicKey =
    'BGebgINZO4LdA9yCla_RcMgmfPOXrzMvEwkk1vKlxA6nhQMK2h_5XBawrISNSMkoF3F93xdq84AZq9knaxWbIqw';
