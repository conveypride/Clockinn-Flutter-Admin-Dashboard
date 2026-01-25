// lib/utils/web_maps_loader.dart
import 'dart:async';
import 'dart:js_interop'; // For newer Flutter versions (3.22+)
// OR use "import 'dart:html';" if you are on an older Flutter version

import 'package:web/web.dart' as web; // Recommended for Flutter 3.22+

Future<void> loadGoogleMaps() async {
  final completer = Completer<void>();

  // 1. Get the Key from the --dart-define environment variable
  const apiKey = String.fromEnvironment('MAPS_API_KEY');

  if (apiKey.isEmpty) {
    print("⚠️ WARNING: MAPS_API_KEY not found in environment variables.");
    return;
  }

  // 2. Check if script is already loaded
  final existingScript = web.document.querySelector('#google-maps-script');
  if (existingScript != null) {
    completer.complete();
    return completer.future;
  }

  // 3. Create the script element
  final script = web.HTMLScriptElement();
  script.id = 'google-maps-script';
  script.src = 'https://maps.googleapis.com/maps/api/js?key=$apiKey&libraries=places&loading=async';
  script.defer = true;
  script.async = true;

  // 4. Listen for load success
  script.onLoad.listen((event) {
    if (!completer.isCompleted) completer.complete();
  });

  // 5. Listen for load errors
  script.onError.listen((event) {
    if (!completer.isCompleted) {
      completer.completeError("Failed to load Google Maps Script");
    }
  });

  // 6. Append to Head
  web.document.head!.append(script);

  return completer.future;
}