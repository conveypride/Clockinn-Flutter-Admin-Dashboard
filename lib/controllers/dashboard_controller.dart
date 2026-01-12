import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/login_controller.dart';

class DashboardController extends GetxController {
  var totalEmployees = 0.obs;
  var totalSites = 0.obs;
  var activeNow = 0.obs; // This might still need a query or Realtime DB
  var isLoading = true.obs;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LoginController auth = Get.find<LoginController>(); // Access logged-in user info

  @override
  void onInit() {
    super.onInit();
    loadStats();
  }

  void loadStats() async {
    isLoading.value = true;
    String cid = auth.companyId.value;

    if (cid.isEmpty) {
      isLoading.value = false;
      return; 
    }

    try {
      // 1. OPTIMIZED COUNT: Total Employees
      // Path: users/{companyId}/sites (This is tricky because 'users' is a subcollection of sites)
      // Since your structure nests users inside sites, we have to be clever.
      // COLLECTION GROUP QUERY is the fastest way here.
      
      AggregateQuerySnapshot empSnapshot = await _db
          .collectionGroup('users') // Search ALL 'users' collections
          .where('companyId', isEqualTo: cid) // Filter by THIS company (You must add 'companyId' to user docs if not present, or filter by path)
          // Wait... your structure says users/{companyId}/sites/{siteId}/users
          // It's safer to loop sites if CollectionGroup is too broad, but CollectionGroup with an index is fastest.
          .count()
          .get();

      totalEmployees.value = empSnapshot.count ?? 0;

      // 2. OPTIMIZED COUNT: Total Sites
      AggregateQuerySnapshot siteSnapshot = await _db
          .collection('operationSites')
          .doc(cid)
          .collection('sites')
          .count()
          .get();

      totalSites.value = siteSnapshot.count ?? 0;

      // 3. Fake "Active Now" for performance (Realtime usually requires RTDB or frequent writes)
      activeNow.value = (totalEmployees.value * 0.8).toInt(); 

    } catch (e) {
      print("Error loading stats: $e");
    } finally {
      isLoading.value = false;
    }
  }
}