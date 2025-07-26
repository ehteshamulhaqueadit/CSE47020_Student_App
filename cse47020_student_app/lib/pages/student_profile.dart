import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cse47020_student_app/api/bracu_auth_manager.dart';
import 'package:cse47020_student_app/model/payment_info.dart';

class StudentProfile extends StatefulWidget {
  const StudentProfile({super.key});

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> {
  Map<String, String?>? _profile = {};
  File? _imageFile;
  List<PaymentInfo> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await BracuAuthManager().getProfile();
    File? image = await BracuAuthManager().getProfileImage();
    final List<dynamic> paymentsJson = jsonDecode(
      await BracuAuthManager().getPaymentInfo() ?? '',
    );
    List<PaymentInfo> payments = paymentsJson
        .map((item) => PaymentInfo.fromJson(item))
        .toList();

    setState(() {
      _profile = profile;
      _imageFile = image;
      _payments = payments;
    });
  }

  Future<void> _refreshProfile() async {
    final profile = await BracuAuthManager().fetchProfile();
    File? image = await BracuAuthManager().fetchProfileImage();
    final List<dynamic> paymentsJson = jsonDecode(
      await BracuAuthManager().fetchPaymentInfo() ?? '',
    );
    List<PaymentInfo> payments = paymentsJson
        .map((item) => PaymentInfo.fromJson(item))
        .toList();

    setState(() {
      _profile = profile;
      _imageFile = image;
      _payments = payments;
    });
  }

  String formatSemester(int semesterSessionId) {
    final year = semesterSessionId ~/ 10;
    final semesterCode = semesterSessionId % 10;

    String semester;
    switch (semesterCode) {
      case 1:
        semester = 'Fall';
        break;
      case 2:
        semester = 'Summer';
        break;
      case 3:
        semester = 'Spring';
        break;
      default:
        semester = 'Unknown';
    }

    return '$semester $year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProfile,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[300],
                    image: _imageFile != null
                        ? DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imageFile == null
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _profile == null
                      ? const Text('Profile Not Available')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Name: ${_profile!['fullName'] ?? 'N/A'}'),
                            Text(
                              'Student ID: ${_profile!['studentId'] ?? 'N/A'}',
                            ),
                            Text('Email: ${_profile!['email'] ?? 'N/A'}'),
                            Text('Program: ${_profile!['program'] ?? 'N/A'}'),
                            Text(
                              'Current Semester: ${_profile!['currentSemester'] ?? 'N/A'}',
                            ),
                            Text(
                              'Earned Credit: ${_profile!['earnedCredit'] ?? 'N/A'}',
                            ),
                          ],
                        ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Payment List - scrollable
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 270, // or any value you prefer
              ),
              child: Card(
                color: Colors.green[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ListView.builder(
                    itemCount: _payments.length,
                    itemBuilder: (context, index) {
                      final payment = _payments[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          leading: const Icon(
                            Icons.payment,
                            color: Colors.green,
                          ),
                          title: Text(
                            'Payslip Number: ${payment.payslipNumber}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Type: ${payment.paymentType} \n'
                            'Status: ${payment.paymentStatus} \n'
                            'Semester: ${formatSemester(payment.semesterSessionId)}'
                            '${payment.paymentStatus != 'PAID' ? '\nDue Date: ${payment.dueDate.toIso8601String().split("T").first}' : ''}',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
