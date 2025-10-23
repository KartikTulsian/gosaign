import 'dart:io';

import 'package:attendance_app/services/attendance_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cross_file/cross_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'model/woman_model.dart';


class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> with WidgetsBindingObserver {

  double screenHeight = 0;
  double screenWidth = 0;

  Color primary = const Color(0xFFFF8F38);

  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> presentList = [];
  List<Map<String, dynamic>> absentList = [];
  List<Map<String, dynamic>> filteredPresentList = [];
  List<Map<String, dynamic>> filteredAbsentList = [];

  String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> attendanceEntries = [];
  bool isLoading = true;

  bool showPresent = true; // true = show present list, false = show absent list

  // Replace with actual admin check from login/session
  bool isAdmin = true;

  String role = '';

  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadRole();
    selectedDate = DateTime.now();
    fetchAttendanceForDate(selectedDate);

    // Listen for search changes
    searchController.addListener(() {
      if (showPresent) {
        _filterPresentList(searchController.text);
      } else {
        _filterAbsentList(searchController.text);
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    // WidgetsBinding.instance.removeObserver(this); // 👈 clean up
    // searchController.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _onSearchFocusChange() {
    if (!_searchFocusNode.hasFocus && searchController.text.isEmpty) {
      setState(() {}); // Trigger rebuild to show placeholder
    }
  }

  Future<void> loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      role = prefs.getString('role') ?? '';
    });
  }

  void _filterPresentList(String query) {
    final lowerQuery = query.toLowerCase();
    final latestEntries = AttendanceService().entriesNotifier.value;

    setState(() {
      if (query.isEmpty) {
        filteredPresentList = List.from(latestEntries);
      } else {
        filteredPresentList = latestEntries.where((entry) {
          return (entry['name'] ?? '').toLowerCase().contains(lowerQuery) ||
              (entry['husbandName'] ?? '').toLowerCase().contains(lowerQuery) ||
              (entry['couponCode'] ?? '').toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  void _filterAbsentList(String query) {
    final lowerQuery = query.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredAbsentList = List.from(absentList);
      } else {
        filteredAbsentList = absentList.where((entry) {
          return (entry['name'] ?? '').toLowerCase().contains(lowerQuery) ||
              (entry['husbandName'] ?? '').toLowerCase().contains(lowerQuery) ||
              (entry['couponCode'] ?? '').toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }


  Future<void> fetchAttendanceForDate(DateTime date) async {
    setState(() {
      isLoading = true;
      absentList = [];
      filteredAbsentList = [];
    });

    final formattedDate = DateFormat('yyyy-MM-dd').format(date);

    // final snapshot = await FirebaseFirestore.instance
    //     .collection('attendance')
    //     .doc(formattedDate)
    //     .collection('entries')
    //     .orderBy('timestamp', descending: true) // 🟢 Sort by timestamp (latest first)
    //     .get();

    final presentFuture = FirebaseFirestore.instance
        .collection('attendance')
        .doc(formattedDate)
        .collection('entries')
        .orderBy('timestamp', descending: true) // 🟢 Sort by timestamp (latest first)
        .get();

    // Prepare absent list only if current time is after 5pm
    final now = DateTime.now();
    final isSameDay = DateUtils.isSameDay(now, date);
    final isFriday = date.weekday == DateTime.friday;
    final afterFivePM = now.hour >= 17;
    final isPastDate = date.isBefore(DateTime(now.year, now.month, now.day));

    Future<QuerySnapshot<Map<String, dynamic>>>? womenFuture;
    if (isFriday && (isPastDate || (isSameDay && afterFivePM))) {
      womenFuture = FirebaseFirestore.instance.collection('women').get();
    }

    // Step 3: Fetch in parallel
    final results = await Future.wait([
      presentFuture,
      if (womenFuture != null) womenFuture,
    ]);

    final presentSnapshot = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final entries = presentSnapshot.docs.map((doc) {
      return {
        ...doc.data(),
        'womanId': doc.id,
      };
    }).toList();

    // Set entries in AttendanceService
    AttendanceService().entriesNotifier.value = entries;
    _filterPresentList(searchController.text);

    // setState(() {
    //   isLoading = false;
    //   _filterPresentList(searchController.text); // update filtered list
    // });

    if (womenFuture != null && results.length > 1) {
      final womenSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;
      final presentIds = entries.map((e) => e['womanId'] as String).toSet();

      absentList = womenSnapshot.docs
          .where((doc) => !presentIds.contains(doc.id))
          .map((doc) => {
            ...doc.data(),
            'womanId': doc.id,
            'status': 'absent',
          })
        .toList();

      absentList.sort((a, b) {
        final aCode = int.tryParse(a['couponCode'].replaceAll(RegExp(r'\D'), '')) ?? 0;
        final bCode = int.tryParse(b['couponCode'].replaceAll(RegExp(r'\D'), '')) ?? 0;
        return aCode.compareTo(bCode);
      });

      filteredAbsentList = List.from(absentList);
    } else {
      absentList = [];
      filteredAbsentList = [];
    }

    // if (isFriday && (isPastDate || (isSameDay && afterFivePM))) {
    //   final presentIds = entries.map((e) => e['womanId'] as String).toSet();
    //
    //   final womenSnapshot = await FirebaseFirestore.instance.collection('women').get();
    //
    //   absentList = womenSnapshot.docs
    //       .where((doc) => !presentIds.contains(doc.id))
    //       .map((doc) => {
    //     ...doc.data(),
    //     'womanId': doc.id,
    //     'status': 'absent',
    //   }).toList();
    //
    //   absentList.sort((a, b) {
    //     final aCode = int.tryParse(a['couponCode'].replaceAll(RegExp(r'\D'), '')) ?? 0;
    //     final bCode = int.tryParse(b['couponCode'].replaceAll(RegExp(r'\D'), '')) ?? 0;
    //     return aCode.compareTo(bCode);
    //   });
    //
    //   filteredAbsentList = List.from(absentList);
    //
    //   // setState(() {}); // Rebuild with absentList
    // }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      await fetchAttendanceForDate(picked);
    }
  }

  Future<void> _removeEntry(String womanId) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);

    try {
      await FirebaseFirestore.instance
          .collection('attendance')
          .doc(dateKey)
          .collection('entries')
          .doc(womanId)
          .delete();

      // setState(() {
      //   presentList.removeWhere((entry) => entry['womanId'] == womanId);
      // });
      AttendanceService().removeEntry(womanId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Entry removed successfully.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error removing entry: $e")),
      );
    }
  }

  Widget _highlightText(String text, String query) {
    if (query.isEmpty) return Text(text, style: const TextStyle(fontSize: 15));

    final matches = text.toLowerCase().contains(query.toLowerCase());
    if (!matches) return Text(text, style: const TextStyle(fontSize: 15));

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    final startIndex = lowerText.indexOf(lowerQuery);
    final endIndex = startIndex + query.length;

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text.substring(0, startIndex),
            style: const TextStyle(fontSize: 15, color: Colors.black),
          ),
          TextSpan(
            text: text.substring(startIndex, endIndex),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          TextSpan(
            text: text.substring(endIndex),
            style: const TextStyle(fontSize: 15, color: Colors.black),
          ),
        ],
      ),
    );
  }

  // Future<void> _loadTodayEntriesFromFirestore() async {
  //   final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
  //
  //   try {
  //     final snapshot = await FirebaseFirestore.instance
  //         .collection('attendance')
  //         .doc(dateKey)
  //         .collection('entries')
  //         .get();
  //
  //     final entries = snapshot.docs.map((doc) {
  //       return {
  //         ...doc.data(),
  //         'womanId': doc.id,
  //       };
  //     }).toList();
  //
  //     // Load only if entriesNotifier is empty to avoid duplication
  //     if (AttendanceService().entriesNotifier.value.isEmpty) {
  //       AttendanceService().entriesNotifier.value = entries;
  //     }
  //   } catch (e) {
  //     debugPrint("Error loading today's attendance: $e");
  //   }
  // }

  Future<void> _downloadCSV() async {
    final entries = AttendanceService().entriesNotifier.value;

    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No data to export.")),
      );
      return;
    }

    List<List<String>> csvData = [
      ['Name', 'Husband Name', 'Address', 'Coupon Code', 'Barcode', 'Time']
    ];

    for (var entry in entries) {
      csvData.add([
        entry['name']?.toString() ?? 'Unnamed',
        entry['husbandName']?.toString() ?? '',
        entry['address']?.toString() ?? '',
        entry['couponCode']?.toString() ?? '',
        entry['barcode']?.toString() ?? '',
        entry['timestamp'] is Timestamp
            ? DateFormat('yyyy-MM-dd hh:mm a').format((entry['timestamp'] as Timestamp).toDate())
            : '',
      ]);
    }

    final now = DateTime.now();
    final fileName = 'attendance_${DateFormat('yyyy-MM-dd_HH-mm').format(now)}.csv';
    final directory = await getExternalStorageDirectory(); // or use getDownloadsDirectory() with permissions
    final file = File('${directory!.path}/$fileName');

    await file.writeAsString(const ListToCsvConverter().convert(csvData));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV exported to ${file.path}')),
    );

    await Share.shareXFiles([XFile(file.path)], text: "Today's Attendance CSV");
    // await SharePlus.instance.share(file: [XFile(file.path)], text: "Today's Attendance CSV");
  }


  Future<void> _downloadPDF() async {
    final entries = AttendanceService().entriesNotifier.value;

    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No data to export.")),
      );
      return;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('Women Attendance List - ${DateFormat('yyyy-MM-dd HH:mm a').format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Name', 'Husband', 'Address', 'Coupon', 'Barcode', 'Time'],
            data: entries.map((e) {
              return [
                e['name'] ?? 'Unnamed',
                e['husbandName'] ?? '',
                e['address'] ?? '',
                e['couponCode'] ?? '',
                e['barcode'] ?? '',
                e['timestamp'] is Timestamp
                    ? DateFormat('yyyy-MM-dd hh:mm a').format((e['timestamp'] as Timestamp).toDate())
                    : '',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'attendance_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.pdf',
    );
  }

  Future<void> _showManualEntryDialog() async {
    final _controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Manual Attendance Entry'),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Text(
                'CPN',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Enter Number',
                  hintText: 'e.g., 345',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final numberOnly = _controller.text.replaceAll(RegExp(r'[^0-9]'), '');
              final code = 'CPN$numberOnly';
              Navigator.pop(ctx); // Close dialog
              if (code.isNotEmpty) {
                await _markAttendanceByCoupon(code);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _markAttendanceByCoupon(String couponCode) async {
    final todayKey = DateFormat('yyyy-MM-dd').format(selectedDate);
    final firestore = FirebaseFirestore.instance;

    try {
      final query = await firestore
          .collection('women')
          .where('couponCode', isEqualTo: couponCode)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No woman found with coupon code $couponCode.")),
        );
        return;
      }

      final doc = query.docs.first;
      final woman = Woman.fromMap(doc.data(), doc.id);

      // Check for duplicate entry first
      final alreadyPresent = await firestore
          .collection('attendance')
          .doc(todayKey)
          .collection('entries')
          .doc(woman.id)
          .get();

      if (alreadyPresent.exists) {
        _showDialog('Duplicate', '${woman.name} is already marked present.');
        return;
      }

// Show confirmation dialog only if not a duplicate
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.check_circle_outline, color: Colors.green),
              SizedBox(width: 8),
              Text('Confirm Attendance'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: CircleAvatar(
                  child: Text(woman.name[0]),
                  backgroundColor: Colors.orange.shade100,
                ),
                title: Text(woman.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(woman.husbandName),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📍 Address: ${woman.address}'),
                    const SizedBox(height: 4),
                    Text('🎟  Coupon: ${woman.couponCode}'),
                    const SizedBox(height: 4),
                    Text('🔢  Barcode: ${woman.barcode}'),
                  ],
                ),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Reject'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Accept'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Prepare and store entry
      final entryData = {
        ...woman.toMap(),
        'timestamp': Timestamp.now(),
        'status': 'present',
      };

      await firestore.collection('attendance').doc(todayKey).set({'exists': true}, SetOptions(merge: true));

      await firestore
          .collection('attendance')
          .doc(todayKey)
          .collection('entries')
          .doc(woman.id)
          .set(entryData);

      AttendanceService().addEntry(entryData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${woman.name} marked present.')),
      );

      // _showDialog('Success', '${woman.name} marked present via manual entry.');
    } catch (e) {
      _showDialog('Error', 'Something went wrong: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    return Scaffold(
          appBar: AppBar(
            title: const Text("Today's Attendance"),
            backgroundColor: primary,
            foregroundColor: Colors.white,
            actions: role == 'admin' || role == 'active'
                ? [
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: "Download CSV",
                onPressed: _downloadCSV,
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: "Download PDF",
                onPressed: _downloadPDF,
              ),
            ]
                : null,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show today's date
              Padding(
                padding: const EdgeInsets.only(
                  left: 10.0,
                  right: 10.0,
                  top: 8.0,
                  bottom: 4.0,
                ),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    title: Text(
                      "Date: $formattedDate",
                      style: TextStyle(
                        fontSize: screenWidth / 21,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    trailing: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => _selectDate(context),
                      child: const CircleAvatar(
                        backgroundColor: Color(0xFFFF8F38),
                        child: Icon(Icons.calendar_month, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),

              ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: AttendanceService().entriesNotifier,
                builder: (context, entries, _) {
                  // WidgetsBinding.instance.addPostFrameCallback((_) {
                  //   if (!mounted) return;
                  //   if (searchController.text.isEmpty) {
                  //     setState(() {
                  //       filteredPresentList = entries;
                  //     });
                  //   } else {
                  //     _filterPresentList(searchController.text); // this already uses setState
                  //   }
                  // });

                  // Directly update filteredPresentList without setState here
                  filteredPresentList = searchController.text.isEmpty
                      ? entries
                      : entries.where((entry) {
                    final query = searchController.text.toLowerCase();
                    return (entry['name'] ?? '').toLowerCase().contains(query) ||
                        (entry['husbandName'] ?? '').toLowerCase().contains(query) ||
                        (entry['couponCode'] ?? '').toLowerCase().contains(query);
                  }).toList();

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() => showPresent = true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: showPresent ? primary : Colors.grey.shade300,
                              foregroundColor: showPresent ? Colors.white : Colors.black87,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                              valueListenable: AttendanceService().entriesNotifier,
                              builder: (context, entries, _) => Text('Present (${entries.length})'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() => showPresent = false);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !showPresent ? primary : Colors.grey.shade300,
                              foregroundColor: !showPresent ? Colors.white : Colors.black87,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text('Absent (${absentList.length})'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10),
                child: TextField(
                  controller: searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Search by Name, Husband, or Coupon',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              Expanded(
                child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: AttendanceService().entriesNotifier,
                  builder: (context, presentList, _) {
                    if (presentList.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.sentiment_dissatisfied, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              "No attendance marked yet.",
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async => fetchAttendanceForDate(selectedDate),
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : showPresent
                          ? _buildPresentList()
                          : _buildAbsentList(),
                    );
                  },
                ),
              ),
            ],
          ),

          floatingActionButton: FloatingActionButton(
            onPressed: _showManualEntryDialog,
            backgroundColor: Colors.orange,
            child: const Icon(Icons.add),
            tooltip: "Manual Attendance Entry",
          ),
    );
  }

  Widget _buildPresentList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredPresentList.length,
      itemBuilder: (context, index) {
        final woman = filteredPresentList[index];
        final timestamp = woman['timestamp'] as Timestamp;
        final timeStr = DateFormat.jm().format(timestamp.toDate());

        return _buildWomanCard(woman, timeStr, isPresent: true);
      },
    );
  }

  Widget _buildAbsentList() {
    if (absentList.isEmpty) {
      return const Center(
        child: Text('Absent list will be available after 5 PM.', style: TextStyle(fontSize: 16)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredAbsentList.length,
      itemBuilder: (context, index) {
        final woman = filteredAbsentList[index];
        return _buildWomanCard(woman, null, isPresent: false);
      },
    );
  }

  Widget _buildWomanCard(Map<String, dynamic> woman, String? timeStr, {required bool isPresent}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isPresent ? Colors.orange.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isPresent ? Colors.green : Colors.red,
            radius: 15,
            child: Icon(
              isPresent ? Icons.check : Icons.close,
              color: Colors.white,
            ),
          ),
          title: _highlightText(woman['name'] ?? 'Unnamed', searchController.text),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _highlightText("Husband: ${woman['husbandName'] ?? ''}", searchController.text),
              const SizedBox(height: 4),
              _highlightText("Coupon: ${woman['couponCode'] ?? ''}", searchController.text),
              if (isPresent && timeStr != null) ...[
                const SizedBox(height: 4),
                Text("Time: $timeStr", style: const TextStyle(fontSize: 15, color: Colors.black54)),
              ],
            ],
          ),
          trailing: isPresent && (role == 'admin' || role == 'active')
              ? IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 28),
            onPressed: () {
              _confirmDelete(context, woman['womanId']);
            },
          )
              : null,
        ),
      ),
    );
  }

  void _showDialog(String title, String message) {
    // FocusScope.of(context).unfocus();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(
              title == 'Duplicate' ? Icons.warning_amber_rounded :
              title == 'Success' ? Icons.check_circle_outline :
              Icons.error_outline,
              color: title == 'Success'
                  ? Colors.green
                  : title == 'Duplicate'
                  ? Colors.orange
                  : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String womanId) {
    showDialog(
      context: context,
      barrierDismissible: false, // prevent tap outside to close
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Confirm Deletion"),
          content: const Text("Are you sure you want to delete this woman's profile? This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), // Close dialog only
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx); // Close dialog first

                AttendanceService().removeEntry(womanId);
                await _removeEntry(womanId);
                // Perform deletion here
                // await _deleteWoman();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }
}