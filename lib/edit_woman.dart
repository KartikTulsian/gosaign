import 'package:attendance_app/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'model/woman_model.dart';

class EditWomanScreen extends StatefulWidget {
  final Woman woman;

  const EditWomanScreen({super.key, required this.woman});

  @override
  State<EditWomanScreen> createState() => _EditWomanScreenState();
}

class _EditWomanScreenState extends State<EditWomanScreen> {

  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController husbandController;
  late TextEditingController addressController;
  // late TextEditingController couponController;
  // late TextEditingController barcodeController;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.woman.name);
    husbandController = TextEditingController(text: widget.woman.husbandName);
    addressController = TextEditingController(text: widget.woman.address);
    // couponController = TextEditingController(text: woman['couponCode']);
    // barcodeController = TextEditingController(text: woman['barcode']);
  }

  Future<void> updateWomanData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final updatedWoman = Woman(
        id: widget.woman.id,
        name: nameController.text.trim(),
        husbandName: husbandController.text.trim(),
        address: addressController.text.trim(),
        couponCode: widget.woman.couponCode,
        barcode: widget.woman.barcode,
      );

      await DatabaseService().updateWoman(updatedWoman);

      if (mounted) {
        Navigator.pop(context, updatedWoman); // Go back to detail screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: ${e.toString()}")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF8F38);

    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(13),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Update Details",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  buildField("Name", nameController),
                  buildField("Husband Name", husbandController),
                  buildField("Address", addressController),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("Update", style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: updateWomanData,
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

  Widget buildField(String label, TextEditingController controller) {
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
