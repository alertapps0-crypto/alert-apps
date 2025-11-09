import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import 'role_select.dart';

class DashboardGuru extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final String teacherEmail;
  final String teacherPhone;

  const DashboardGuru({
    Key? key,
    required this.teacherId,
    required this.teacherName,
    required this.teacherEmail,
    required this.teacherPhone,
  }) : super(key: key);

  @override
  _DashboardGuruState createState() => _DashboardGuruState();
}

class _DashboardGuruState extends State<DashboardGuru> {
  // Search controller and query state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Future<String?> _showSendNotificationDialog() async {
    final TextEditingController messageController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return showDialog<String>(
      // Explicitly specify return type as String
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Kirim Notifikasi Darurat',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Mengirim ke ${selectedParentIds.length} penerima',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop("Anak mengalami tantrum");
                  },
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(
                            Icons.warning,
                            size: 30,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(
                            "Anak mengalami tantrum",
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    Navigator.of(context)
                        .pop("Anak sakit, perlu pertolongan pertama");
                  },
                  child: Container(
                    height: 60,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(
                            Icons.medical_services,
                            size: 30,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Text(
                              "Anak sakit, perlu pertolongan pertama",
                              style: TextStyle(
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop("Jam sekolah selesai");
                  },
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(
                            Icons.check_circle,
                            size: 30,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(
                            "Jam sekolah selesai",
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop("Periksa suhu tubuh");
                  },
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(
                            Icons.sick,
                            size: 30,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(
                            "Periksa suhu tubuh",
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey,
                      ),
                      borderRadius: BorderRadius.all(
                        Radius.circular(12),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey,
                      ),
                      borderRadius: BorderRadius.all(
                        Radius.circular(12),
                      ),
                    ),
                    hintText: 'Masukkan pesan...',
                    border: OutlineInputBorder(),
                    labelText: 'Pesan darurat',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Harap masukkan pesan';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(messageController.text);
                }
              },
              child: const Text(
                'Send',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<String> selectedParentIds = [];
  bool isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff5f5f5),
      appBar: AppBar(
        backgroundColor: Color(0xfff5f5f5),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                widget.teacherName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(
                widget.teacherEmail,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 40,
                ),
                backgroundColor: Colors.grey,
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.settings,
                size: 30,
              ),
              title: Text(
                'Pengaturan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 20,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Text(
                  "Pilih Penerima",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    fontSize: 18,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey[700],
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    labelStyle: TextStyle(
                      fontSize: 18,
                    ),
                    filled: true,
                    fillColor: Color(0xfffafafa),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(15),
                      ),
                    ),
                    hintText: "Cari Nama",
                    hintStyle: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[700],
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim();
                    });
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
              ),
              child: Text(
                'Pengguna yang dipilih: ${selectedParentIds.length}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 16.0,
              ),
              child: Text(
                "Orang Tua",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // List: Parents
                      StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .where('role', isEqualTo: 'parent')
                            .snapshots(),
                        builder:
                            (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error: ${snapshot.error}',
                                overflow: TextOverflow.visible,
                                softWrap: true,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final sortedDocs = snapshot.data!.docs.toList()
                            ..sort((a, b) => (a['name'] as String)
                                .compareTo(b['name'] as String));

                          final filteredDocs = _searchQuery.isEmpty
                              ? sortedDocs
                              : sortedDocs
                                  .where((doc) => (doc['name'] ?? '')
                                      .toString()
                                      .toLowerCase()
                                      .contains(_searchQuery.toLowerCase()))
                                  .toList();

                          return Column(
                            children: [
                              ...filteredDocs.map((parent) => Column(
                                    children: [
                                      CheckboxListTile(
                                        secondary: CircleAvatar(
                                          radius: 30,
                                          backgroundColor: Color(0xff007AFF),
                                          child: Text(
                                            parent['name'].toString().isNotEmpty
                                                ? parent['name'][0]
                                                    .toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                              color: Color(0xfffefefe),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 24,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          parent['name'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium,
                                        ),
                                        value: selectedParentIds
                                            .contains(parent.id),
                                        onChanged: (bool? value) {
                                          setState(() {
                                            if (value == true) {
                                              selectedParentIds.add(parent.id);
                                            } else {
                                              selectedParentIds
                                                  .remove(parent.id);
                                            }
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      const Divider(),
                                    ],
                                  )),
                            ],
                          );
                        },
                      ),

                      // Section header: Security
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 8.0,
                          right: 8.0,
                          top: 8.0,
                          bottom: 8.0,
                        ),
                        child: Text(
                          "Security",
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),

                      // List: Security
                      StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .where('role', isEqualTo: 'security')
                            .snapshots(),
                        builder:
                            (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error: ${snapshot.error}',
                                overflow: TextOverflow.visible,
                                softWrap: true,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final sortedDocs = snapshot.data!.docs.toList()
                            ..sort((a, b) => (a['name'] as String)
                                .compareTo(b['name'] as String));

                          final filteredDocs = _searchQuery.isEmpty
                              ? sortedDocs
                              : sortedDocs
                                  .where((doc) => (doc['name'] ?? '')
                                      .toString()
                                      .toLowerCase()
                                      .contains(_searchQuery.toLowerCase()))
                                  .toList();

                          return Column(
                            children: [
                              ...filteredDocs.map((user) => Column(
                                    children: [
                                      CheckboxListTile(
                                        secondary: CircleAvatar(
                                          radius: 30,
                                          backgroundColor: Color(0xff007AFF),
                                          child: Text(
                                            user['name'].toString().isNotEmpty
                                                ? user['name'][0].toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                              color: Color(0xfffefefe),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 24,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          user['name'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium,
                                        ),
                                        value:
                                            selectedParentIds.contains(user.id),
                                        onChanged: (bool? value) {
                                          setState(() {
                                            if (value == true) {
                                              selectedParentIds.add(user.id);
                                            } else {
                                              selectedParentIds.remove(user.id);
                                            }
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      const Divider(),
                                    ],
                                  )),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        height: 70,
        width: 75,
        child: FloatingActionButton(
          onPressed: isLoading || selectedParentIds.isEmpty
              ? () async {
                  if (selectedParentIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select at least one recipient'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                }
              : () async {
                  final String? message =
                      await _showSendNotificationDialog(); // Explicitly type the message

                  if (message != null) {
                    setState(() {
                      isLoading = true;
                    });

                    try {
                      final notificationService =
                          context.read<NotificationService?>();
                      if (notificationService == null) {
                        throw Exception('NotificationService not available');
                      }

                      await notificationService.sendEmergencyNotification(
                        teacherId: widget.teacherId,
                        teacherName: widget.teacherName,
                        parentIds: selectedParentIds,
                        message: message,
                        teacherPhone: widget.teacherPhone,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Emergency notification sent successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      setState(() {
                        selectedParentIds.clear();
                      });
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to send notification: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } finally {
                      setState(() {
                        isLoading = false;
                      });
                    }
                  }
                },
          backgroundColor: Color(0xff007AFF),
          child: Container(
            child: isLoading
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : const Icon(
                    Icons.send,
                    color: Color(0xfffefefe),
                    size: 30,
                  ),
          ),
        ),
      ),
    );
  }
}
