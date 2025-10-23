import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// class AddDummyWomenScreen extends StatefulWidget {
//   const AddDummyWomenScreen({super.key});
//
//   @override
//   State<AddDummyWomenScreen> createState() => _AddDummyWomenScreenState();
// }
//
// class _AddDummyWomenScreenState extends State<AddDummyWomenScreen> {
//   bool _isLoading = false;
//   String _status = "";
//
//   Future<void> addDummyWomen() async {
//     setState(() {
//       _isLoading = true;
//       _status = "Adding dummy women...";
//     });
//
//     final womenCollection = FirebaseFirestore.instance.collection("women");
//
//     try {
//       for (int i = 1; i <= 500; i++) {
//         await womenCollection.add({
//           "name": "Woman $i",
//           "husbandName": "Husband $i",
//           "address": "Address $i",
//           "couponCode": "CPN$i",
//           "barcode": "BARCODE$i",
//         });
//
//         // Optional: Add delay if you get rate-limit errors on free Firebase
//         // await Future.delayed(Duration(milliseconds: 10));
//       }
//
//       setState(() {
//         _status = "✅ Successfully added 500 dummy women!";
//       });
//     } catch (e) {
//       setState(() {
//         _status = "❌ Failed: ${e.toString()}";
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Add Dummy Women")),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Center(
//           child: _isLoading
//               ? Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const CircularProgressIndicator(),
//               const SizedBox(height: 16),
//               Text(_status),
//             ],
//           )
//               : Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               ElevatedButton(
//                 onPressed: addDummyWomen,
//                 child: const Text("Add 500 Dummy Women"),
//               ),
//               const SizedBox(height: 20),
//               Text(_status),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

class UpdateWomanIdsScreen extends StatefulWidget {
  const UpdateWomanIdsScreen({super.key});

  @override
  State<UpdateWomanIdsScreen> createState() => _UpdateWomanIdsScreenState();
}

class _UpdateWomanIdsScreenState extends State<UpdateWomanIdsScreen> {
  bool _isLoading = false;
  String _status = "";

  Future<void> updateWomanIds() async {
    setState(() {
      _isLoading = true;
      _status = "Updating womanId for all documents...";
    });

    final womenCollection = FirebaseFirestore.instance.collection("women");

    try {
      final snapshot = await womenCollection.get();

      int updatedCount = 0;

      for (final doc in snapshot.docs) {
        await womenCollection.doc(doc.id).update({
          "womanId": doc.id,
        });
        updatedCount++;
      }

      setState(() {
        _status = "✅ Updated $updatedCount women with their womanId!";
      });
    } catch (e) {
      setState(() {
        _status = "❌ Failed: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update womanId")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: _isLoading
              ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(_status),
            ],
          )
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: updateWomanIds,
                child: const Text("Update womanId in all documents"),
              ),
              const SizedBox(height: 20),
              Text(_status),
            ],
          ),
        ),
      ),
    );
  }
}