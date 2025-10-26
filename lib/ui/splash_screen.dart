import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 230,
              height: 230,
              child: Image.asset("assets/images/logo_umy.png"),
            ),
            const SizedBox(
              height: 10,
            ),
            Column(
              children: [
                Text(
                  "UNIVERSITAS",
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff007A3D),
                  ),
                ),
                Text(
                  "MUHAMMADIYAH",
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff007A3D),
                  ),
                ),
                Text(
                  "YOGYAKARTA",
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff007A3D),
                  ),
                ),
                SizedBox(
                  height: 35,
                ),
                Text(
                  "SLB NEGERI PEMBINA YOGYAKARTA",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 100,
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Color(0xff007A3D),
                    fixedSize:
                        Size(MediaQuery.of(context).size.width * 0.8, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, "/roleselect");
                  },
                  child: Text(
                    "Mulai",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
