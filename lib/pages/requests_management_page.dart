import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:iconsax/iconsax.dart';
import '../models/lawyer_request.dart';
import '../services/api_client.dart';

class RequestManagementPage extends StatefulWidget {
  const RequestManagementPage({super.key});

  @override
  State<RequestManagementPage> createState() => _RequestManagementPageState();
}

class _RequestManagementPageState extends State<RequestManagementPage> {
  List<LawyerRequest> _requests = [];
  bool _loading = true;

  static const String splashPageRoute = '/splash';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ApiClient.getPendingRequests();
      setState(() {
        _requests = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('خطأ في الاتصال: $e')));
    }
  }

  Future<void> _updateRequestStatus(LawyerRequest r, String newStatus) async {
    try {
      await ApiClient.updateRequestStatus(requestId: r.id, status: newStatus);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('تم ${newStatus == "Approved" ? "قبول" : "رفض"} الطلب'),
      ));
      _load(); // إعادة التحديث
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  void _onApprove(LawyerRequest r) => _updateRequestStatus(r, 'Approved');
  void _onDecline(LawyerRequest r) => _updateRequestStatus(r, 'Rejected');

  void _onLogout() {
    Navigator.of(context).pushReplacementNamed(splashPageRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      backgroundColor: const Color.fromARGB(255, 9, 44, 36),
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: const Text(
        'الطلبات',
        style: TextStyle(color: Colors.white),
      ),

      actions: [
        TextButton.icon(
          onPressed: _onLogout,
          label: const Text(
            'تسجيل الخروج',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          icon: const Icon(Iconsax.logout, color: Colors.white, size: 20),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('لا يوجد طلبات'))
              : ListView.builder(
                  itemCount: _requests.length,
                  itemBuilder: (_, i) => RequestCard(
                    request: _requests[i],
                    onApprove: _onApprove,
                    onDecline: _onDecline,
                  ),
                ),
              );
             }
          }

class RequestCard extends StatelessWidget {
  final LawyerRequest request;
  final void Function(LawyerRequest) onApprove;
  final void Function(LawyerRequest) onDecline;

  const RequestCard({
    super.key,
    required this.request,
    required this.onApprove,
    required this.onDecline,
  });
//show file
  Future<void> _openPDFTemporary(BuildContext context, String url) async {
    try {
      if (url.isEmpty) throw 'رابط الملف غير متوفر';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) {
        throw 'فشل تحميل الملف (${res.statusCode})';
      }

      final tmp = await getTemporaryDirectory();
      final name = url.split('/').last;
      final path = '${tmp.path}/$name';

      final f = File(path);
      await f.writeAsBytes(res.bodyBytes);

      await OpenFile.open(path);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('تعذّر فتح الملف: $e')));
    }
  }
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // التفاصيل
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(request.lawyerName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('رقم الرخصة: ${request.licenseNumber}',
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF333333))),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 130,
                    child: ElevatedButton(
                     onPressed: () => _openPDFTemporary(context, request.LicenseFile),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 9, 44, 36),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('عرض الرخصة'),
                    ),
                  ),
                ],
              ),
            ),

            // الإجراءات
            Column(
              children: [
                SizedBox(
                  width: 100,
                  child: OutlinedButton(
                    onPressed: () => onApprove(request),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color.fromARGB(255, 9, 44, 36),
                        width: 2.5,
                      ),
                      foregroundColor: const Color.fromARGB(255, 9, 44, 36),
                    ),
                    child: const Text('قبول'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 100,
                  child: OutlinedButton(
                    onPressed: () => onDecline(request),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color.fromARGB(255, 160, 11, 0),
                        width: 2.5,
                      ),
                      foregroundColor: const Color.fromARGB(255, 160, 11, 0),
                    ),
                    child: const Text('رفض'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
