import 'package:attendance_app/logoutscreen.dart';
import 'package:attendance_app/scan_attendance.dart';
import 'package:attendance_app/profilescreen.dart';
import 'package:attendance_app/todayscreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  double screenHeight = 0;
  double screenWidth = 0;

  Color primary = const Color(0xFFFF8F38);
  final LinearGradient primaryGradient = const LinearGradient(
    colors: [Color(0xFFFF8F38), Color(0xFFFF4B14)],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );


  int currentIndex = 0;

  List<IconData> navigationIcons = [
    FontAwesomeIcons.barcode,
    FontAwesomeIcons.check,
    FontAwesomeIcons.userLarge,
    FontAwesomeIcons.rightFromBracket,
  ];


  @override
  Widget build(BuildContext context) {
    // final bool isKeyboardVisible = KeyboardVisibilityProvider.isKeyboardVisible(context);
    screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    return Scaffold(
      body: IndexedStack(
        index: currentIndex < 3 ? currentIndex : 0, // Avoid error if logout is selected
        children: const [
          ScannerScreen(),
          TodayScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: MediaQuery.of(context).viewPadding.bottom + 8, // Proper padding
        ),
        child: Container(
          height: 70,

          decoration: BoxDecoration(
            gradient: primaryGradient,
            borderRadius: const BorderRadius.all(
              Radius.circular(40),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(2, 2),
              )
            ]
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(
              Radius.circular(40),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int i = 0; i < navigationIcons.length; i++)...<Expanded>{
                  Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (i == 3) {
                            showLogoutPopup(context);
                          } else {
                            setState(() {
                              currentIndex = i;
                            });
                          }
                        },
                        child: Container(
                          // height: screenHeight,
                          // width: screenWidth,
                          color: Colors.transparent,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  navigationIcons[i],
                                  color: i == currentIndex ? Colors.white : Colors.black54,
                                  size: i == currentIndex ? 30 : 26,
                                ),
                                i == currentIndex ? Container(
                                  margin: const EdgeInsets.only(
                                    top: 6,
                                  ),
                                  height: 3,
                                  width: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(40),
                                    ),
                                  ),
                                ) : const SizedBox(),
                              ],
                            ),
                          ),
                        ),
                      )
                  )
                }
              ],
            ),
          ),
        ),
      ),
    );
  }
  void showLogoutPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 180,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Are you sure you want to logout?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.logout, color: Colors.white,),
                    label: const Text("Logout"),
                    onPressed: () {
                      Navigator.pop(context); // Close popup
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LogOutScreen()),
                      );
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFDEBFF),
                    ),
                    child: const Text("Cancel"),
                    onPressed: () {
                      Navigator.pop(context); // Just close popup
                    },
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
