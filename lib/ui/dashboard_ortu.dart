import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'riwayat_pesan.dart';
import 'role_select.dart';

class DashboardOrtu extends StatefulWidget {
  final String parentId;
  final String parentName;
  final String parentEmail;

  const DashboardOrtu({
    Key? key,
    required this.parentId,
    required this.parentName,
    required this.parentEmail,
  }) : super(key: key);

  @override
  State<DashboardOrtu> createState() => _DashboardOrtuState();
}

class _DashboardOrtuState extends State<DashboardOrtu> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff5f5f5),
      appBar: AppBar(
        backgroundColor: Color(0xfff5f5f5),
        centerTitle: true,
        title: Text(
          "Wireless Calling System",
          overflow: TextOverflow.visible,
          softWrap: true,
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                widget.parentName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(
                widget.parentEmail,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xff007AFF),
                child: Text(
                  widget.parentName.toString().isNotEmpty
                      ? widget.parentName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: Color(0xfffefefe),
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.history,
                size: 30,
              ),
              title: Text(
                'Riwayat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RiwayatPesan(
                      userId: widget.parentId,
                    ),
                  ),
                );
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Colors.red,
                size: 30,
              ),
              title: Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => RoleSelect()),
                  (Route<dynamic> route) =>
                      false, // hapus semua halaman sebelumnya
                );
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: SizedBox(
                  width: 300,
                  child: Text(
                    "Selamat Datang, Bapak/Ibu ${widget.parentName}",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
