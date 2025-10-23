import 'dart:io';

import 'package:attendance_app/create_woman.dart';
import 'package:attendance_app/model/woman_model.dart';
import 'package:attendance_app/services/database_service.dart';
import 'package:attendance_app/view_women.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String role = '';
  TextEditingController searchController = TextEditingController();
  List<Woman> women = [];
  List<Woman> filteredWomen = [];

  int totalCount = 0;

  Color primary = const Color(0xFFFF8F38);
  final LinearGradient primaryGradient = const LinearGradient(
    colors: [Color(0xFFFF8F38), Color(0xFFFF4B14)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );


  @override
  void initState() {
    super.initState();
    loadRole();

    // Add this:
    searchController.addListener(() {
      _filterWomen(searchController.text);
    });
  }

  Future<void> loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      role = prefs.getString('role') ?? '';
    });
  }

  void _filterWomen(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredWomen = women;
      } else {
        final lowerQuery = query.toLowerCase();
        filteredWomen = women.where((woman) {
          // Check if name starts with query (prefix match)
          final nameMatch = woman.name.toLowerCase().startsWith(lowerQuery);

          // Check if coupon contains query (substring match)
          final couponMatch = woman.couponCode.toLowerCase().contains(lowerQuery);

          return nameMatch || couponMatch;
        }).toList();

        // Sort results so name matches come first in lexicographic order
        filteredWomen.sort((a, b) {
          final aName = a.name.toLowerCase();
          final bName = b.name.toLowerCase();

          // If both match by name, sort lexicographically
          if (aName.startsWith(lowerQuery) && bName.startsWith(lowerQuery)) {
            return aName.compareTo(bName);
          }

          // Prioritize name matches over coupon matches
          if (aName.startsWith(lowerQuery)) return -1;
          if (bName.startsWith(lowerQuery)) return 1;

          // Otherwise keep coupon order as is
          return a.couponCode.compareTo(b.couponCode);
        });
      }
    });
  }

  Widget _highlightMatch(String source, String query, {bool prefixOnly = false}) {

    if (query.isEmpty) return Text(source);

    final lowerSource = source.toLowerCase();
    final lowerQuery = query.toLowerCase();

    int matchIndex;
    if (prefixOnly) {
      matchIndex = lowerSource.startsWith(lowerQuery) ? 0 : -1;
    } else {
      matchIndex = lowerSource.indexOf(lowerQuery);
    }

    // final matchIndex = source.toLowerCase().indexOf(query.toLowerCase());
    if (matchIndex == -1) return Text(source);

    final before = source.substring(0, matchIndex);
    final match = source.substring(matchIndex, matchIndex + query.length);
    final after = source.substring(matchIndex + query.length);

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: before, style: TextStyle(color: Colors.black)),
          TextSpan(
              text: match,
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          TextSpan(text: after, style: TextStyle(color: Colors.black)),
        ],
      ),
    );
  }

  Future<void> _exportToCSV() async {
    List<List<String>> csvData = [
      ['Id', 'Name', 'Husband Name', 'Address', 'Coupon Code', 'Barcode']
    ];

    for (var woman in filteredWomen) {
      // final data = woman.data() as Map<String, dynamic>;
      csvData.add([
        woman.id,
        woman.name,
        woman.husbandName,
        woman.address,
        woman.couponCode,
        woman.barcode,
      ]);
    }

    final now = DateTime.now();
    final fileName = 'women_list_${DateFormat('yyyy-MM-dd_HH-mm').format(now)}.csv';
    final dir = await getExternalStorageDirectory();
    final path = '${dir!.path}/$fileName';
    final file = File(path);

    await file.writeAsString(const ListToCsvConverter().convert(csvData));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV exported to ${file.path}')),
    );

    await Share.shareXFiles([XFile(file.path)], text: "Women List CSV");
  }

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('Women List_${DateFormat('yyyy-MM-dd HH:mm a').format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Id', 'Name', 'Husband', 'Address', 'Coupon', 'Barcode'],
            data: filteredWomen.map((e) {
              // final data = e.data() as Map<String, dynamic>;
              return [
                e.id,
                e.name,
                e.husbandName,
                e.address,
                e.couponCode,
                e.barcode];
            }).toList(),
          )
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'Women_List_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFF8F38),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text("Women List"),
          elevation: 0,
          backgroundColor: Color(0xFFFF8F38),
          foregroundColor: Colors.white,
          actions: role == 'admin'
              ? [
            IconButton(
              icon: Icon(Icons.download),
              onPressed: _exportToCSV,
              tooltip: 'Export CSV',
            ),
            IconButton(
              icon: Icon(Icons.picture_as_pdf),
              onPressed: _exportToPDF,
              tooltip: 'Export PDF',
            )
          ]
              : null,
        ),
        body: StreamBuilder<List<Woman>>(
          stream: DatabaseService().getWomenStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text("Error loading data"));
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
      
            women = snapshot.data!;
            // Sort women by numeric part of couponCode (e.g., "CPN123")
            women.sort((a, b) {
              final aCode = int.tryParse(a.couponCode.replaceAll(RegExp(r'\D'), '')) ?? 0;
              final bCode = int.tryParse(b.couponCode.replaceAll(RegExp(r'\D'), '')) ?? 0;
              return aCode.compareTo(bCode);
            });
      
            totalCount = women.length;
      
            // ONLY update filteredWomen if it's the first load or when data changes
            if (searchController.text.isEmpty) {
              filteredWomen = women;
            }
      
            return Column(
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: EdgeInsets.only(
                      left: 14,
                      right: 14,
                      top: 10,
                      bottom: 4,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(Icons.groups, color: primary),
                        SizedBox(width: 10),
                        Text(
                          "Total Women: $totalCount",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Search by Name, Husband, Address or Coupon',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: _filterWomen,
                  ),
                ),
      
                Expanded(
                  child: filteredWomen.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_off, size: 80, color: Colors.grey[400]),
                        Text("No matching results",
                            style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                      ],
                    ),
                  )
                      : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filteredWomen.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final woman = filteredWomen[index];
                      final query = searchController.text;
      
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WomanDetailScreen(woman: woman),
                              ),
                            );
      
                            if (result == true) {
                              setState(() {
                                filteredWomen.removeWhere((w) => w.id == woman.id);
                                women.removeWhere((w) => w.id == woman.id);
                              });
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.person, color: primary, size: 20),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: query.isNotEmpty
                                          ? _highlightMatch(woman.name, query, prefixOnly: true)
                                          : Text(woman.name, style: TextStyle(fontSize: 16)),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.male, color: Colors.grey),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: query.isNotEmpty
                                          ? _highlightMatch("Husband: ${woman.husbandName}", query)
                                          : Text("Husband: ${woman.husbandName}"),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.home, color: Colors.grey),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: query.isNotEmpty
                                          ? _highlightMatch("Address: ${woman.address}", query)
                                          : Text("Address: ${woman.address}"),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.confirmation_number, color: Colors.grey),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: query.isNotEmpty
                                          ? _highlightMatch("Coupon: ${woman.couponCode}", query)
                                          : Text("Coupon: ${woman.couponCode}",
                                          style: TextStyle(color: Colors.grey[900])),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      
              ],
            );
          },
        ),
      
        floatingActionButton: role == "admin"
            ? Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddWomanScreen()),
                );
              },
              label: Text("Add Woman"),
              icon: Icon(Icons.person_add),
              heroTag: "addWoman",
            ),
            SizedBox(height: 10),
            // FloatingActionButton.extended(
            //   onPressed: _updateAllWomanIds,
            //   label: Text("Update womanId"),
            //   icon: Icon(Icons.update),
            //   backgroundColor: Colors.deepPurpleAccent,
            //   heroTag: "updateWomanId",
            // ),
            // TEMPORARY: For adding 500 dummy women
            // FloatingActionButton.extended(
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (_) => const AddDummyWomenScreen()),
            //     );
            //   },
            //   label: Text("Add Dummy"),
            //   icon: Icon(Icons.auto_fix_high),
            //   backgroundColor: Colors.orangeAccent,
            //   heroTag: "addDummy",
            // ),
          ],
        )
            : null,
      ),
    );
  }
}
