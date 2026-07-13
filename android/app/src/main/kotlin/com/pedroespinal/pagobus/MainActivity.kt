package com.pedroespinal.pagobus

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth (biometric unlock) requires a FragmentActivity, not a plain
// FlutterActivity — it uses BiometricPrompt under the hood.
class MainActivity : FlutterFragmentActivity()
