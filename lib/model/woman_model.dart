import 'package:cloud_firestore/cloud_firestore.dart';

class Woman {
  final String id;
  final String name;
  final String husbandName;
  final String address;
  final String couponCode;
  final String barcode;

  Woman({
    required this.id,
    required this.name,
    required this.husbandName,
    required this.address,
    required this.couponCode,
    required this.barcode,
  });

  // Convert Firestore document to Woman model
  factory Woman.fromMap(Map<String, dynamic> data, String documentId) {
    return Woman(
      id: documentId,
      name: data['name'] ?? '',
      husbandName: data['husbandName'] ?? '',
      address: data['address'] ?? '',
      couponCode: data['couponCode'] ?? '',
      barcode: data['barcode'] ?? '',
    );
  }


  // Convert Woman model to Firestore-friendly map
  // Map<String, dynamic> toMap() {
  //   return {
  //     'womanId': id,
  //     'name': name,
  //     'husbandName': husbandName,
  //     'address': address,
  //     'couponCode': couponCode,
  //     'barcode': barcode,
  //   };
  // }
  Map<String, dynamic> toMap() {
    return {
      'womanId': id,
      'name': name.isNotEmpty ? name : 'N/A',
      'husbandName': husbandName.isNotEmpty ? husbandName : 'N/A',
      'address': address.isNotEmpty ? address : 'N/A',
      'couponCode': couponCode.isNotEmpty ? couponCode : 'N/A',
      'barcode': barcode.isNotEmpty ? barcode : 'N/A',
    };
  }

}
