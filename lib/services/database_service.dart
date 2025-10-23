import 'package:attendance_app/model/woman_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final CollectionReference _womanCollection =
  FirebaseFirestore.instance.collection('women');

  // Get all women (stream)
  Stream<List<Woman>> getWomenStream() {
    return _womanCollection.orderBy("name").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Woman.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Add a new woman
  Future<void> addWoman(Woman woman) {
    return _womanCollection.add(woman.toMap());
  }

  // Update an existing woman
  Future<void> updateWoman(Woman woman) {
    return _womanCollection.doc(woman.id).update(woman.toMap());
  }

  // Delete a woman
  Future<void> deleteWoman(String id) {
    return _womanCollection.doc(id).delete();
  }
}
