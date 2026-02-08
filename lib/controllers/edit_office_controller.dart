import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart'; // 1. Added Cloud Functions
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../util/google_place_suggestion.dart'; // 2. Import your model
import 'login_controller.dart'; 

class EditOfficeController extends GetxController {
  final Map<String, dynamic> siteData;
  final String siteId;

  EditOfficeController({required this.siteData, required this.siteId});

  // Inputs
  late TextEditingController siteNameCtrl;
  late TextEditingController openTimeCtrl;
  late TextEditingController closeTimeCtrl;
  late TextEditingController latCtrl;
  late TextEditingController lngCtrl;
  final searchCtrl = TextEditingController();

  final holidayNameCtrl = TextEditingController();
  final holidayDateCtrl = TextEditingController();

  Completer<GoogleMapController> mapController = Completer();
  
  var isLoading = false.obs;
  var selectedRadius = 100.0.obs;
  var workingDays = <String>[].obs;
  var holidays = <Map<String, String>>[].obs;
  var isHQ = false.obs;

  var currentImageUrl = "".obs; 
  var selectedImageName = "".obs; 
  XFile? pickedImage;

  var markers = <Marker>{}.obs;
  var circles = <Circle>{}.obs;

  // 3. NEW: Search State
  var suggestions = <PlaceSuggestion>[].obs;
  var isSearching = false.obs;
  Timer? _debounce;

  final List<String> daysOfWeek = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  final List<int> radiusOptions = [10, 20, 50, 100, 200, 500, 1000];
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  void _initializeData() {
    siteNameCtrl = TextEditingController(text: siteData['nameofsite']);
    openTimeCtrl = TextEditingController(text: siteData['openingTime']);
    closeTimeCtrl = TextEditingController(text: siteData['closingTime']);
    latCtrl = TextEditingController(text: siteData['lat']);
    lngCtrl = TextEditingController(text: siteData['lng']);
    searchCtrl.text = siteData['location'] ?? "";

    selectedRadius.value = (siteData['radius'] as num).toDouble();
    isHQ.value = siteData['isHQ'] ?? false;

    if (siteData['workingdays'] != null) {
      workingDays.assignAll(List<String>.from(siteData['workingdays']));
    }

    currentImageUrl.value = siteData['officeimage'] ?? "";

    if (siteData['holidaylist'] != null) {
      List<dynamic> dbHolidays = siteData['holidaylist'];
      List<Map<String, String>> uiHolidays = [];
      for (var item in dbHolidays) {
        if (item is Map) {
          String key = item.keys.first;
          String val = item.values.first;
          uiHolidays.add({"name": key, "date": val});
        }
      }
      holidays.assignAll(uiHolidays);
    }

    double lat = double.tryParse(siteData['lat']) ?? 0.0;
    double lng = double.tryParse(siteData['lng']) ?? 0.0;
    _updateMapVisuals(LatLng(lat, lng));
  }

  // ---------------------------------------------------------
  // 🔍 NEW: SEARCH & AUTOCOMPLETE LOGIC
  // ---------------------------------------------------------
  
  // 1. Called when user types in search box
  void onSearchChanged(String input) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (input.isNotEmpty) {
        _fetchSuggestions(input);
      } else {
        suggestions.clear();
      }
    });
  }

  // 2. Call Cloud Function to get list of places
  Future<void> _fetchSuggestions(String input) async {
    isSearching.value = true;
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('getPlacesAutocomplete')
          .call({'input': input});

      List<dynamic> predictions = result.data['predictions'];
      suggestions.value = predictions
          .map((json) => PlaceSuggestion.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      print("Autocomplete Error: $e");
    } finally {
      isSearching.value = false;
    }
  }

  // 3. Call Cloud Function to get Lat/Lng for selected place
  Future<void> selectSuggestion(PlaceSuggestion place) async {
    searchCtrl.text = place.description; // Set text to full address
    suggestions.clear(); // Hide list
    isSearching.value = true;

    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('getPlaceDetails')
          .call({'placeId': place.placeId});

      // Parse Lat/Lng from Google Response
      var location = result.data['result']['geometry']['location'];
      double lat = location['lat'];
      double lng = location['lng'];

      // Update Map & Controllers
      latCtrl.text = lat.toString();
      lngCtrl.text = lng.toString();
      
      LatLng newPos = LatLng(lat, lng);
      _updateMapVisuals(newPos);
      
      // Move Camera
      final GoogleMapController map = await mapController.future;
      map.animateCamera(CameraUpdate.newLatLng(newPos));

    } catch (e) {
      Get.snackbar("Error", "Could not fetch location details: $e");
    } finally {
      isSearching.value = false;
    }
  }

  // ---------------------------------------------------------
  // 🚀 UPDATE LOGIC (Existing)
  // ---------------------------------------------------------
  void updateOffice() async {
    if (siteNameCtrl.text.isEmpty) {
      Get.snackbar("Error", "Office Name is required");
      return;
    }

    final loginCtrl = Get.find<LoginController>();
    if (loginCtrl.userRole.value == "Branch Manager") {
      if (loginCtrl.managedSiteId.value != siteId) {
        Get.snackbar("Access Denied", "You are not authorized to edit this office.");
        return;
      }
    }

    try {
      isLoading.value = true;
      String uid = _auth.currentUser!.uid;
      DocumentSnapshot adminDoc = await _db.collection('adminusers').doc(uid).get();
      String companyId = adminDoc['companyId'];

      String finalImageUrl = currentImageUrl.value;
      if (pickedImage != null) {
        finalImageUrl = await _uploadFile(pickedImage!);
      }

      List<Map<String, String>> formattedHolidays = holidays.map((h) {
        return { h['name']! : h['date']! }; 
      }).toList();

      WriteBatch batch = _db.batch();

      if (isHQ.value == true) {
        var currentHQSnap = await _db.collection('operationSites')
            .doc(companyId).collection('sites')
            .where('isHQ', isEqualTo: true).get();

        for (var doc in currentHQSnap.docs) {
          if (doc.id != siteId) {
            batch.update(doc.reference, {'isHQ': false});
          }
        }
      }

      DocumentReference thisOfficeRef = _db.collection('operationSites')
          .doc(companyId).collection('sites').doc(siteId);

      batch.update(thisOfficeRef, {
        'nameofsite': siteNameCtrl.text.trim(),
        'location': searchCtrl.text.isNotEmpty ? searchCtrl.text.trim() : siteNameCtrl.text.trim(),
        'openingTime': openTimeCtrl.text.trim(),
        'closingTime': closeTimeCtrl.text.trim(),
        'workingdays': workingDays,
        'holidaylist': formattedHolidays,
        'lat': latCtrl.text.trim(),
        'lng': lngCtrl.text.trim(),
        'lon': lngCtrl.text.trim(), // Legacy support
        'radius': selectedRadius.value,
        'officeimage': finalImageUrl,
        'isHQ': isHQ.value,
      });

      await batch.commit();
      Get.back(); 
      Get.snackbar("Success", "Office updated successfully!", backgroundColor: Colors.green, colorText: Colors.white);

    } catch (e) {
      Get.snackbar("Error", e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // --- HELPERS ---
  void _updateMapVisuals(LatLng pos) {
    latCtrl.text = pos.latitude.toString();
    lngCtrl.text = pos.longitude.toString();
    markers.clear();
    markers.add(Marker(markerId: const MarkerId('office'), position: pos, draggable: true, onDragEnd: (newPos) => _updateMapVisuals(newPos)));
    circles.clear();
    circles.add(Circle(circleId: const CircleId('radius'), center: pos, radius: selectedRadius.value, fillColor: Colors.blue.withOpacity(0.3), strokeColor: Colors.blue, strokeWidth: 1));
  }

  void updateRadius(double newRadius) {
    selectedRadius.value = newRadius;
    double lat = double.tryParse(latCtrl.text) ?? 0.0;
    double lng = double.tryParse(lngCtrl.text) ?? 0.0;
    _updateMapVisuals(LatLng(lat, lng));
  }

  void pickImage() async {
    final ImagePicker picker = ImagePicker();
    pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      selectedImageName.value = pickedImage!.name;
    }
  }

  Future<String> _uploadFile(XFile file) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('officeImages/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
      Uint8List fileBytes = await file.readAsBytes();
      final uploadTask = storageRef.putData(fileBytes, SettableMetadata(contentType: 'image/jpeg'));
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Upload Error: $e");
      return "";
    }
  }

  void addHoliday() {
    if (holidayNameCtrl.text.isEmpty || holidayDateCtrl.text.isEmpty) return;
    holidays.add({"name": holidayNameCtrl.text, "date": holidayDateCtrl.text});
    holidayNameCtrl.clear();
    holidayDateCtrl.clear();
  }

  void removeHoliday(int index) => holidays.removeAt(index);

  void toggleDay(String day) {
    if (workingDays.contains(day)) {
      workingDays.remove(day);
    } else {
      workingDays.add(day);
    }
  }
  
  void onMapCreated(GoogleMapController controller) {
    mapController.complete(controller);
  }
}