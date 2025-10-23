import 'package:attendance_app/edit_woman.dart';
import 'package:attendance_app/model/woman_model.dart';
import 'package:attendance_app/services/database_service.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WomanDetailScreen extends StatefulWidget {
  final Woman woman;
  final int totalSessions;
  final int attendedSessions;

  const WomanDetailScreen({
    super.key,
    required this.woman,
    this.totalSessions = 50,
    this.attendedSessions = 40,
  });

  @override
  State<WomanDetailScreen> createState() => _WomanDetailScreenState();
}

class _WomanDetailScreenState extends State<WomanDetailScreen> {
  String role = '';
  late Woman woman;

  int totalSessions = 0;
  int attendedSessions = 0;
  bool isLoading = true;

  final allFridays = <String>[];

  Set<String> presentFridays = {};

  @override
  void initState() {
    super.initState();
    woman = widget.woman; // create mutable local copy
    loadRole();
    fetchAttendanceStats();
  }

  // Future<void> fetchAttendanceStats() async {
  //   final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
  //
  //   try {
  //     final snapshot = await FirebaseFirestore.instance
  //         .collection('attendance')
  //         .doc(date) // e.g., '2025-06-11'
  //         .collection('entries')
  //         .where('womanId', isEqualTo: woman.id)
  //         .get();
  //
  //
  //     final allDocs = snapshot.docs;
  //
  //     // Filter out only Friday sessions
  //     final fridayAttendances = allDocs.where((doc) {
  //       final ts = doc['date'] as Timestamp;
  //       final date = ts.toDate().toLocal();
  //       return date.weekday == DateTime.friday;
  //     }).toList();
  //
  //     // Count total Friday sessions (assuming each Friday has one attendance per woman)
  //     final fridaysSet = <String>{};
  //     for (var doc in fridayAttendances) {
  //       final ts = doc['date'] as Timestamp;
  //       final dateStr = DateFormat('yyyy-MM-dd').format(ts.toDate());
  //       fridaysSet.add(dateStr); // unique Friday dates
  //     }
  //
  //     // Count how many of those are present
  //     int presentCount = 0;
  //     for (var doc in fridayAttendances) {
  //       if (doc['status'] == 'present' || doc['status'] == true) {
  //         presentCount++;
  //       }
  //     }
  //
  //     if (mounted) {
  //       setState(() {
  //         totalSessions = fridaysSet.length;
  //         attendedSessions = presentCount;
  //         isLoading = false;
  //       });
  //     }
  //   } catch (e) {
  //     print("Error fetching attendance: $e");
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  // Future<void> fetchAttendanceStats() async {
  //   try {
  //     final attendanceCollection = FirebaseFirestore.instance.collection('attendance');
  //     final dateDocs = await attendanceCollection.get(); // get all dates
  //
  //     final List<QueryDocumentSnapshot<Map<String, dynamic>>> allEntries = [];
  //     final startDate = DateTime(2025, 6, 1);
  //
  //     print("Total attendance date docs: ${dateDocs.docs.length}");
  //
  //     for (final doc in dateDocs.docs) {
  //       final date = doc.id; // e.g., '2025-06-11'
  //
  //       final entriesSnapshot = await attendanceCollection
  //           .doc(date)
  //           .collection('entries')
  //           .where('womanId', isEqualTo: woman.id) // 'id' comes from woman.toMap()
  //           .get();
  //
  //       print("Date $date → Entries for woman: ${entriesSnapshot.docs.length}");
  //
  //       final filteredDocs = entriesSnapshot.docs.where((entry) {
  //         final ts = entry['timestamp'] as Timestamp;
  //         final dt = ts.toDate();
  //         // return dt.isAfter(startDate.subtract(const Duration(days: 1))); // inclusive from June 1
  //         return !dt.isBefore(startDate); // includes startDate and later
  //       });
  //
  //       allEntries.addAll(filteredDocs);
  //
  //       // allEntries.addAll(entriesSnapshot.docs);
  //     }
  //
  //     final fridayAttendances = allEntries.where((doc) {
  //       final ts = doc['timestamp'] ?? doc['date'];
  //       if (ts is! Timestamp) return false;
  //       final dt = ts.toDate();
  //       return dt.weekday == DateTime.friday;
  //     }).toList();
  //
  //     final fridaysSet = <String>{};
  //     for (var doc in fridayAttendances) {
  //       final ts = doc['timestamp'] as Timestamp;
  //       final dateStr = DateFormat('yyyy-MM-dd').format(ts.toDate());
  //       fridaysSet.add(dateStr); // unique Friday sessions
  //     }
  //
  //     int presentCount = 0;
  //     for (var doc in fridayAttendances) {
  //       final status = doc['status'];
  //       print('Status on ${doc['timestamp']}: $status');
  //       if (doc['status'] == 'present' || doc['status'] == true) {
  //         presentCount++;
  //       }
  //     }
  //
  //     if (mounted) {
  //       setState(() {
  //         totalSessions = fridaysSet.length;
  //         attendedSessions = presentCount;
  //         isLoading = false;
  //       });
  //     }
  //   } catch (e) {
  //     print("Error fetching attendance: $e");
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  Future<void> fetchAttendanceStats() async {
    // final presentFridays = <String>{};

    try {
      final startDate = DateTime(2025, 6, 27);
      final today = DateTime.now();



      // Step 1: Generate all Friday dates from June 27, 2025, to today

      DateTime date = startDate;
      while (!date.isAfter(today)) {
        if (date.weekday == DateTime.friday) {
          allFridays.add(DateFormat('yyyy-MM-dd').format(date));
        }
        date = date.add(const Duration(days: 1));
      }

      print("✅ Total Fridays (total sessions): ${allFridays.length}");

      // Step 2: Check if the woman is marked present on those Fridays
      final attendanceCollection = FirebaseFirestore.instance.collection('attendance');
      int presentCount = 0;

      for (final friday in allFridays) {
        final entrySnapshot = await attendanceCollection
            .doc(friday)
            .collection('entries')
            .doc(woman.id)
            .get();

        if (entrySnapshot.exists) {
          final status = entrySnapshot['status'];
          final ts = entrySnapshot['timestamp'];
          print("📅 $friday → Status: $status, Timestamp: ${ts is Timestamp ? ts.toDate() : 'N/A'}");

          if (status == 'present' || status == true) {
            presentCount++;
            presentFridays.add(friday); // ✅ Track date string
          }

        } else {
          print("📅 $friday → Not marked");
        }
      }

      // Step 3: Update state with totals
      if (mounted) {

        setState(() {
          totalSessions = allFridays.length; // All valid Friday sessions
          attendedSessions = presentCount;   // Present sessions only
          isLoading = false;
          this.presentFridays = presentFridays;
        });
      }
    } catch (e) {
      print("❌ Error fetching attendance stats: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      role = prefs.getString('role') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    // var woman = this.woman;
    final total = totalSessions;
    final attended = attendedSessions;
    final missed = total - attended;

    // Simulated attendance summary (replace with real data later)
    // final totalSessions = woman['totalSessions'] ?? 50;
    // final attended = woman['attendedSessions'] ?? 40;
    // final missed = totalSessions - attended;

    const Color primaryColor = Color(0xFFFF8F38);
    const Color bgColor = Color(0xFFFFF3E6);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(woman.name),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          if (role == 'admin' || role == 'active') ...[
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () async {
                final updatedWoman = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditWomanScreen(woman: woman),
                  ),
                );

                if (updatedWoman != null && mounted) {
                  setState(() {
                    this.woman = updatedWoman;
                  });
                }
              },
            ),
            if (role == 'admin')...[
              IconButton(
                icon: Icon(Icons.delete, color: Colors.white),
                onPressed: () => _confirmDelete(context),
              ),
            ]
          ],
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: "Refresh Attendance",
            onPressed: () {
              setState(() => isLoading = true);
              fetchAttendanceStats();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
        color: Color(0xFFFFF3E6),
        padding: const EdgeInsets.all(12.0),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 20
            ),
            child: ListView(
              children: [
                // const SizedBox(height: 15),
                // Center(
                //   child: Icon(Icons.person_pin, size: 90, color: primaryColor),
                // ),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.person_pin, size: 90, color: primaryColor),
                      const SizedBox(height: 10),
                      Text(
                        woman.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // const SizedBox(height: 5),
                      // Text(
                      //   "ID: ${woman.id}",
                      //   style: TextStyle(color: Colors.grey[700]),
                      // ),
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                Divider(thickness: 1.5, color: Colors.grey[500]),
                const SizedBox(height: 8),
                Text("Personal Info",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: "NotoSansBold",
                        color: primaryColor)),
                const SizedBox(height: 10),
                // InfoRow(label: "Name", value: woman.name, icon: Icons.person),
                InfoRow(label: "Husband Name", value: woman.husbandName, icon: Icons.man),
                InfoRow(label: "Address", value: woman.address, icon: Icons.home),
                InfoRow(label: "Coupon Code", value: woman.couponCode, icon: Icons.receipt),
                InfoRow(label: "Woman Id", value: woman.id, icon: Icons.fingerprint),
                const SizedBox(height: 15),
                if ((role == "admin" || role == "active") && woman.barcode.isNotEmpty) ...[
                  Divider(thickness: 1.2, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    "Barcode",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: primaryColor
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  BarcodeWidget(
                    barcode: Barcode.code128(),
                    data: woman.barcode,
                    width: 200,
                    height: 80,
                  ),
                ],
                const SizedBox(height: 24),
                Divider(thickness: 1.5, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  "Attendance Summary",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                _buildStatBox("Total", "$total", Colors.blueGrey[700]!),
                _buildStatBox("Present", "$attended", Colors.green[600]!),
                _buildStatBox("Absent", "$missed", Colors.red[600]!),
                const SizedBox(height: 10),
                Divider(thickness: 1.5, color: Colors.grey[400]),

                const SizedBox(height: 8),
                Text(
                  "Attendance History",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                _buildStatList(allFridays),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
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
                // Perform deletion here
                await _deleteWoman();
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

  Future<void> _deleteWoman() async {
    try {
      await DatabaseService().deleteWoman(widget.woman.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Woman deleted successfully.")),
        );
        Navigator.pop(context, true); // Go back to previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete: ${e.toString()}")),
        );
      }
    }
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatList(List<String> dates) {
    // Sort dates in reverse order (latest first)
    final sortedDates = List<String>.from(dates)..sort((a, b) => b.compareTo(a));

    return SizedBox(
      height: 300, // ✅ fixed height for scrollable area
      child: ListView.builder(
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final isPresent = presentFridays.contains(date);
          final statusText = isPresent ? 'Present' : 'Absent';
          final statusColor = isPresent ? Colors.green : Colors.red;
          final statusIcon = isPresent ? Icons.check_circle : Icons.cancel;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withOpacity(0.5)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(
                  date,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFFFF8F38), size: 24,),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              "$label:",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: "NotoSansBold",
                  fontSize: 16
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class AttendanceRow extends StatelessWidget {
  final String label;
  final String value;

  const AttendanceRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "$label:",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }
}