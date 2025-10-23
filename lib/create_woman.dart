import 'package:attendance_app/model/woman_model.dart';
import 'package:attendance_app/services/database_service.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddWomanScreen extends StatefulWidget {
  const AddWomanScreen({super.key});

  @override
  State<AddWomanScreen> createState() => _AddWomanScreenState();
}

class _AddWomanScreenState extends State<AddWomanScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final husbandController = TextEditingController();
  final addressController = TextEditingController();

  bool isLoading = false;
  String? generatedBarcode;

  Future<String> _generateUniqueCode(
      String prefix, String fieldName, int startIndex) async {
    int index = startIndex;

    final collection = FirebaseFirestore.instance.collection('women');

    while (true) {
      final code = "$prefix$index";

      // Check if this code already exists
      final exists = await collection
          .where(fieldName, isEqualTo: code)
          .limit(1)
          .get();

      if (exists.docs.isEmpty) {
        return code;
      }

      index++;
    }
  }

  Future<void> _createWoman() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      generatedBarcode = null;
    });

    try {
      final countSnapshot =
      await FirebaseFirestore.instance.collection('women').get();
      final startIndex = countSnapshot.docs.length + 1;

      // Generate unique couponCode and barcode
      final couponCode = await _generateUniqueCode("CPN", "couponCode", startIndex);
      final barcode = await _generateUniqueCode("BARCODE", "barcode", startIndex);

      // Step 1: Create doc ref with auto ID
      final docRef = FirebaseFirestore.instance.collection('women').doc();

      // Step 2: Create Woman object using this ID
      final newWoman = Woman(
        id: docRef.id,
        name: nameController.text.trim(),
        husbandName: husbandController.text.trim(),
        address: addressController.text.trim(),
        couponCode: couponCode,
        barcode: barcode,
      );

      // await DatabaseService().addWoman(newWoman);

      // Step 3: Add the woman to Firestore with the ID embedded
      await docRef.set(newWoman.toMap());

      setState(() {
        generatedBarcode = barcode;
        isLoading = false;
      });

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Success",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Woman profile created successfully."),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      "Coupon Code: $couponCode",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 14),
                    BarcodeWidget(
                      data: barcode,
                      barcode: Barcode.code128(),
                      width: 200,
                      height: 70,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, true); // Navigate back
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF8F38), // primary orange
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                "OK",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF8F38);

    return Scaffold(
      appBar: AppBar(
        title: Text("Add Woman",  style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(13),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    "Enter Woman Details",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField("Name", nameController),
                  _buildTextField("Husband Name", husbandController),
                  _buildTextField("Address", addressController),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _createWoman,
                      icon: const Icon(Icons.check_circle),
                      label: const Text("Create Profile", style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.grey),
          ),
        ),
        validator: (value) => value == null || value.isEmpty ? "Enter $label" : null,
      ),
    );
  }

}