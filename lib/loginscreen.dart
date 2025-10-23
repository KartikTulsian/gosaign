import 'package:attendance_app/home_admin.dart';
import 'package:attendance_app/home_member.dart';
import 'package:attendance_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController idController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  double screenHeight = 0;
  double screenWidth = 0;

  Color primary = const Color(0xFFFF8F38);
  final LinearGradient primaryGradient = const LinearGradient(
    colors: [Color(0xFFFF8F38), Color(0xFFFF4B14)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  late SharedPreferences sharedPreferences;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

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
      resizeToAvoidBottomInset: false,
      body: KeyboardVisibilityBuilder(
        builder: (context, isKeyboardVisible) {
          return Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isKeyboardVisible ? SizedBox(height: screenHeight / 16,)
                  : Container(
                height: screenHeight / 3,
                width: screenWidth,
                decoration: BoxDecoration(
                  gradient: primaryGradient,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(70),
                    bottomRight: Radius.circular(70),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orangeAccent.withOpacity(0.4),
                      offset: const Offset(0, 5),
                      blurRadius: 12,
                    )
                  ],
                ),
                child: Center(
                  // child: Icon(
                  //     Icons.person,
                  //     color: Colors.white,
                  //     size: screenWidth / 5
                  // ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/gosaiji.png',
                      width: screenWidth / 3,
                      height: screenWidth / 3,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(
                  top: screenHeight / 20,
                  bottom: screenHeight / 20,
                ),
                child: Text(
                  "Login",
                  style: TextStyle(
                    fontSize: screenWidth / 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: "NotoSansBold",
                    color: const Color(0xFF333333),
                    letterSpacing: 1,
                  ),
                ),
              ),
              Container(
                  alignment: Alignment.centerLeft,
                  margin: EdgeInsets.symmetric(
                    horizontal: screenWidth / 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      fieldTitle("Bhakt Id"),
                      customField("Enter Your Id", idController, false),
                      fieldTitle("Password"),
                      customField(
                          "Enter Your Password", passwordController, true),
                      GestureDetector(
                        // onTap: () async {
                        //   FocusScope.of(context).unfocus();
                        //   String id = idController.text.trim().toLowerCase();
                        //   String password = passwordController.text.trim();
                        //
                        //   if (id.isEmpty) {
                        //     ScaffoldMessenger.of(context).showSnackBar(
                        //       const SnackBar(
                        //         content: Text("Please Enter Your Id"),
                        //       ),
                        //     );
                        //   } else if (password.isEmpty) {
                        //     ScaffoldMessenger.of(context).showSnackBar(
                        //       const SnackBar(
                        //         content: Text("Please Enter Your Password"),
                        //       ),
                        //     );
                        //   } else {
                        //     QuerySnapshot snap = await FirebaseFirestore
                        //         .instance.collection("Gosai_bhakt").where("id", isEqualTo: id).get();
                        //
                        //     print("Login Attempt for ID: $id");
                        //     print("Documents Found: ${snap.docs.length}");
                        //     if (snap.docs.isNotEmpty) {
                        //       print("Matched Document Data: ${snap.docs[0].data()}");
                        //     }
                        //
                        //     // print(snap.docs[0]['id']);
                        //     try {
                        //       if (snap.docs.isEmpty) {
                        //         ScaffoldMessenger.of(context).showSnackBar(
                        //           const SnackBar(content: Text("Invalid Id")),
                        //         );
                        //         return;
                        //       }
                        //
                        //       if (password == snap.docs[0]['password']) {
                        //         String role = snap.docs[0]['role'];
                        //         // print("Login Successful");
                        //         sharedPreferences =
                        //         await SharedPreferences.getInstance();
                        //         await sharedPreferences.setString("id", id);
                        //         await sharedPreferences.setString("role", role);
                        //
                        //         // sharedPreferences.setString("id", id).then((_) {
                        //         //   Navigator.push(
                        //         //     context,
                        //         //     MaterialPageRoute(
                        //         //       builder: (context) => HomeScreen(),
                        //         //     ),
                        //         //   );
                        //         // });
                        //         if (role == "admin") {
                        //           Navigator.pushReplacement(
                        //             context,
                        //             MaterialPageRoute(
                        //               builder: (context) => AdminHomeScreen(),
                        //             ),
                        //           );
                        //         } else {
                        //           Navigator.pushReplacement(
                        //             context,
                        //             MaterialPageRoute(
                        //               builder: (context) => MemberHomeScreen(),
                        //             ),
                        //           );
                        //         }
                        //       } else {
                        //         ScaffoldMessenger.of(context).showSnackBar(
                        //           SnackBar(
                        //             content: Text("Password Incorrect"),
                        //           ),
                        //         );
                        //       }
                        //     } catch (e) {
                        //       String error = " ";
                        //       // print(e.toString());
                        //       if (e.toString() ==
                        //           "RangeError (length): Invalid value: Valid value range is empty: 0") {
                        //         setState(() {
                        //           error = "Invalid Id";
                        //         });
                        //       } else {
                        //         setState(() {
                        //           error = "Something Went Wrong";
                        //         });
                        //       }
                        //
                        //       ScaffoldMessenger.of(context).showSnackBar(
                        //         SnackBar(
                        //           content: Text(error),
                        //         ),
                        //       );
                        //     }
                        //   }
                        // },
                        onTap: () async {
                          FocusScope.of(context).unfocus();
                          String id = idController.text.trim().toLowerCase();
                          String password = passwordController.text.trim();

                          if (id.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please Enter Your Id")),
                            );
                            return;
                          }

                          if (password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please Enter Your Password")),
                            );
                            return;
                          }

                          final authService = AuthService();
                          String? result = await authService.loginWithIdPassword(id, password);

                          if (result == null) {
                            // Login success
                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            String? role = prefs.getString("role");

                            if (role == "admin") {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
                              );
                            } else {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const MemberHomeScreen()),
                              );
                            }
                          } else {
                            // Login failed
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result)),
                            );
                          }
                        },

                        child: Container(
                          height: 55,
                          width: screenWidth,
                          margin: EdgeInsets.only(
                            top: screenHeight / 40,
                          ),
                          decoration: BoxDecoration(
                            gradient: primaryGradient,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(30),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              )
                            ],
                          ),
                          child: Center(
                            child: Text(
                              "LOGIN",
                              style: TextStyle(
                                fontFamily: "LatoBold",
                                fontSize: screenWidth / 20,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  )
              )
            ],
          );
        },
      ),
    );
  }


  Widget fieldTitle(String title) {
    return Container(
      margin: const EdgeInsets.only(
          bottom: 12
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: screenWidth / 21,
          fontFamily: "LatoRegular",
        ),
      ),
    );
  }

  Widget customField(String hintText, TextEditingController controller, bool obscureText) {
    return Container(
        width: screenWidth,
        margin: EdgeInsets.only(
            // bottom: screenHeight / 50
          bottom: 16,
        ),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 5),
              )
            ]
        ),
        child: Row(
          children: [
            Container(
              width: screenWidth / 6,
              child: Icon(
                Icons.person,
                color: primary,
                size: screenWidth / 15,
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: screenWidth / 12),
                child: TextFormField(
                  controller: controller,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      vertical: screenHeight / 35,
                    ),
                    border: InputBorder.none,
                    hintText: hintText,
                  ),
                  maxLines: 1,
                  obscureText: obscureText,
                ),
              ),
            )
          ],
        )
    );
  }
}