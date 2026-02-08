import 'dart:async';
import 'dart:typed_data'; 
import 'package:clockinn_flutter_admin/util/google_place_suggestion.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:firebase_storage/firebase_storage.dart';

class SetupOfficeController extends GetxController {
  // Inputs
  final siteNameCtrl = TextEditingController();
  final openTimeCtrl = TextEditingController(text: "08:30");
  final closeTimeCtrl = TextEditingController(text: "17:00");
  
  // Holiday Inputs
  final holidayNameCtrl = TextEditingController();
  final holidayDateCtrl = TextEditingController();

  // Map & Location
  Completer<GoogleMapController> mapController = Completer();
  final latCtrl = TextEditingController(text: "5.6037"); // Accra Default
  final lngCtrl = TextEditingController(text: "-0.1870");
  
  
  // Observables
  var isLoading = false.obs;
  var selectedRadius = 100.0.obs;
  var workingDays = <String>[].obs; // ["mon", "tue"]
  var holidays = <Map<String, String>>[].obs; // [{"name": "Xmas", "date": "2025-12-25"}]
  var selectedImageName = "".obs;
  XFile? pickedImage;

  // Map Markers & Circles
  var markers = <Marker>{}.obs;
  var circles = <Circle>{}.obs;

  // Constants
  final List<String> daysOfWeek = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  final List<int> radiusOptions = [10, 20, 50, 100, 200, 500, 1000];

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // NEW: Search Input
  final searchCtrl = TextEditingController();
  // NEW: Debounce Timer to prevent API spam
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    // Initialize Map with default Accra location
    _updateMapVisuals(LatLng(5.6037, -0.1870));
    // NEW: Load default holidays automatically
    _loadDefaultHolidays();
  }


// ---------------------------------------------------------
  // NEW: Auto-Populate Ghanaian Holidays
  // ---------------------------------------------------------
  void _loadDefaultHolidays() {
    int year = DateTime.now().year;
    
    // Fixed Holidays
    List<Map<String, String>> defaults = [
      {'name': "New Year's Day", 'date': "$year-01-01"},
      {'name': "Constitution Day", 'date': "$year-01-07"},
      {'name': "Independence Day", 'date': "$year-03-06"},
      {'name': "May Day", 'date': "$year-05-01"},
      {'name': "Founders' Day", 'date': "$year-08-04"},
      {'name': "Kwame Nkrumah Memorial Day", 'date': "$year-09-21"},
      {'name': "Christmas Day", 'date': "$year-12-25"},
      {'name': "Boxing Day", 'date': "$year-12-26"},
    ];

    // Add Dynamic Holidays (Approximate for 2026)
    // You can use a package like 'calculus' for exact Easter dates if needed
    if (year == 2026) {
      defaults.add({'name': "Good Friday", 'date': "2026-04-03"});
      defaults.add({'name': "Easter Monday", 'date': "2026-04-06"});
      defaults.add({'name': "Eid al-Fitr (Approx)", 'date': "2026-03-20"}); 
      defaults.add({'name': "Eid al-Adha (Approx)", 'date': "2026-05-27"});
      defaults.add({'name': "Farmers' Day", 'date': "2026-12-04"}); // 1st Friday of Dec
    }

    holidays.assignAll(defaults);
  }
 Future<List<PlaceSuggestion>> fetchSuggestions(String input) async {
    if (input.isEmpty) return [];

    try {
      // Call the Cloud Function instead of HTTP
      final result = await FirebaseFunctions.instance
          .httpsCallable('getPlacesAutocomplete')
          .call({'input': input});

      final data = result.data; // This is the JSON response from Google
      
      if (data['status'] == 'OK') {
        return (data['predictions'] as List)
            .map((p) => PlaceSuggestion.fromJson(Map<String, dynamic>.from(p)))
            .toList();
      }
    } catch (e) {
      print("Cloud Function Error: $e");
    }
    return [];
  }

  Future<void> onSuggestionSelected(PlaceSuggestion suggestion) async {
    try {
      // Call Cloud Function for details
      final result = await FirebaseFunctions.instance
          .httpsCallable('getPlaceDetails')
          .call({'placeId': suggestion.placeId});

      final data = result.data;
      
      if (data['status'] == 'OK') {
        final location = data['result']['geometry']['location'];
        final LatLng newPos = LatLng(location['lat'], location['lng']);
        
        // ... (Rest of your map update logic remains the same) ...
        final GoogleMapController controller = await mapController.future;
        controller.animateCamera(CameraUpdate.newLatLngZoom(newPos, 16));
        _updateMapVisuals(newPos);
        searchCtrl.text = suggestion.description;
      }
    } catch (e) {
      Get.snackbar("Error", "Could not fetch details");
    }
  }
 
  // --- MAP LOGIC ---
  void onMapCreated(GoogleMapController controller) {
    mapController.complete(controller);
  }

  void _updateMapVisuals(LatLng pos) {
    latCtrl.text = pos.latitude.toString();
    lngCtrl.text = pos.longitude.toString();

    markers.clear();
    markers.add(Marker(
      markerId: const MarkerId('office'),
      position: pos,
      draggable: true,
      onDragEnd: (newPos) => _updateMapVisuals(newPos),
    ));

    circles.clear();
    circles.add(Circle(
      circleId: const CircleId('radius'),
      center: pos,
      radius: selectedRadius.value,
      fillColor: Colors.blue.withOpacity(0.3),
      strokeColor: Colors.blue,
      strokeWidth: 1,
    ));
  }

  void updateRadius(double newRadius) {
    selectedRadius.value = newRadius;
    // Refresh circle with existing lat/lng
    double lat = double.tryParse(latCtrl.text) ?? 5.6037;
    double lng = double.tryParse(lngCtrl.text) ?? -0.1870;
    _updateMapVisuals(LatLng(lat, lng));
  }

  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar("Error", "Location services are disabled.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition();
      LatLng newPos = LatLng(position.latitude, position.longitude);
      
      final GoogleMapController controller = await mapController.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(newPos, 16));
      _updateMapVisuals(newPos);
      
    } catch (e) {
      Get.snackbar("Error", "Could not get location: $e");
    }
  }

  // --- IMAGE LOGIC ---
  void pickImage() async {
    final ImagePicker picker = ImagePicker();
    pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      selectedImageName.value = pickedImage!.name;
    }
  }

  // --- HOLIDAY LOGIC ---
  void addHoliday() {
    if (holidayNameCtrl.text.isEmpty || holidayDateCtrl.text.isEmpty) {
      Get.snackbar("Error", "Please fill name and date");
      return;
    }
    holidays.add({
      "name": holidayNameCtrl.text,
      "date": holidayDateCtrl.text
    });
    holidayNameCtrl.clear();
    holidayDateCtrl.clear();
  }

  void removeHoliday(int index) {
    holidays.removeAt(index);
  }

  void toggleDay(String day) {
    if (workingDays.contains(day)) {
      workingDays.remove(day);
    } else {
      workingDays.add(day);
    }
  }


Future<String> uploadFile(XFile file) async {
  try {
    // Create a reference to 'officeImages/filename.jpg'
    final storageRef = FirebaseStorage.instance.ref().child('officeImages/${file.name}');
    
    // For Web, we must upload raw bytes
    Uint8List fileBytes = await file.readAsBytes();
    
    // Upload
    final uploadTask = storageRef.putData(
      fileBytes, 
      SettableMetadata(contentType: 'image/jpeg') // Helps browser display it correctly
    );

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  } catch (e) {
    print("Upload Error: $e");
    return "";
  }
}

  // --- SAVE LOGIC ---
   // --- SAVE LOGIC ---
  void createFirstOffice() async {
     // 1. Basic Validation
    if (siteNameCtrl.text.isEmpty) {
      Get.snackbar("Error", "Office Name is required");
      return;
    }
    if (workingDays.isEmpty) {
      Get.snackbar("Error", "Select at least one working day");
      return;
    }

    try {
      isLoading.value = true;
      String uid = _auth.currentUser!.uid;

      // 2. Get Company ID from Admin Profile
      DocumentSnapshot adminDoc = await _db.collection('adminusers').doc(uid).get();
      String companyId = adminDoc['companyId'];

      // ============================================================
      // 🚀 LOGIC: AUTOMATIC HQ DETECTION
      // ============================================================
      // Fetch the company document to check how many sites exist
      DocumentSnapshot companyDoc = await _db.collection('companies').doc(companyId).get();
      int existingCount = 0;
      
      if (companyDoc.exists && companyDoc.data() != null) {
        var data = companyDoc.data() as Map<String, dynamic>;
        existingCount = data['countOperationSites'] ?? 0;
      }

      // If count is 0, this is the FIRST office => isHQ = true
      // If count > 0, this is just another branch => isHQ = false
      bool isHQ = existingCount == 0;
      // ============================================================

      // 3. Upload Image (if selected)
      String imageUrl = ""; 
      if (pickedImage != null) {
        imageUrl = await uploadFile(pickedImage!);
      }

      // 4. Format Holidays
      List<Map<String, String>> formattedHolidays = holidays.map((h) {
        return { h['name']! : h['date']! }; 
      }).toList();

      // 5. Save to Firestore
      String siteId = _db.collection('operationSites').doc(companyId).collection('sites').doc().id;

      await _db.collection('operationSites').doc(companyId).collection('sites').doc(siteId).set({
        // Identity
        'nameofsite': siteNameCtrl.text.trim(),
        'location': searchCtrl.text.isNotEmpty ? searchCtrl.text.trim() : siteNameCtrl.text.trim(),
        
        // Time & Dates
        'openingTime': openTimeCtrl.text.trim(),
        'closingTime': closeTimeCtrl.text.trim(),
        'workingdays': workingDays,
        'holidaylist': formattedHolidays,
        'datejoined': FieldValue.serverTimestamp(),
        
        // Coordinates
        'lat': latCtrl.text.trim(),
        'lng': lngCtrl.text.trim(),
        'lon': lngCtrl.text.trim(),
        'radius': selectedRadius.value,
        
        // Status & Assets
        'isHQ': isHQ, // <--- USES THE DETECTED VALUE
        'status': true, 
        'officeimage': imageUrl
      });

      // 6. Update Company Document (Increment Count & Add Name)
      await _db.collection('companies').doc(companyId).update({
        'countOperationSites': FieldValue.increment(1),
        'department': FieldValue.arrayUnion([siteNameCtrl.text.trim()])
      });

      // 7. Navigation
      // If this was the first setup, go to dashboard. 
      // If adding from dashboard, go back.
      if (isHQ) {
        Get.offAllNamed('/dashboard');
      } else {
        Get.back(); // Close the screen if adding a secondary office
        Get.snackbar("Success", "New branch added successfully!");
      }

    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}