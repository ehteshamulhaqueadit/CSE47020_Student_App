import 'package:flutter/material.dart';
import 'package:cse47020_student_app/api/bracu_auth_manager.dart';

class AdvisingInfoPage extends StatefulWidget {
  const AdvisingInfoPage({super.key});

  @override
  State<AdvisingInfoPage> createState() => _AdvisingInfoPageState();
}

class _AdvisingInfoPageState extends State<AdvisingInfoPage> {
  Map<String, String?>? advisingInfo;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdvisingInfo();
  }

  Future<void> _loadAdvisingInfo() async {
    final info = await BracuAuthManager().getAdvisingInfo();
    setState(() {
      advisingInfo = info;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (advisingInfo == null) {
      return const Scaffold(
        body: Center(child: Text("No advising info available")),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow("Advising Start", advisingInfo!["advisingStartDate"]),
            _buildInfoRow("Advising End", advisingInfo!["advisingEndDate"]),
            _buildInfoRow("Phase", advisingInfo!["advisingPhase"]),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value ?? "Not available"),
        ],
      ),
    );
  }
}

