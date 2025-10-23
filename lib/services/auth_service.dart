import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firestore-based login
  Future<String?> loginWithIdPassword(String id, String password) async {
    try {
      final snap = await _firestore
          .collection("Gosai_bhakt")
          .where("id", isEqualTo: id)
          .get();

      if (snap.docs.isEmpty) return "Invalid Id";

      final doc = snap.docs[0];
      if (doc['password'] != password) return "Password Incorrect";

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("id", id);
      await prefs.setString("role", doc['role']);

      return null; // null means success
    } catch (e) {
      return "Login Failed: ${e.toString()}";
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<String?> getSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("role");
  }

  Future<String?> getSavedId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("id");
  }
}
