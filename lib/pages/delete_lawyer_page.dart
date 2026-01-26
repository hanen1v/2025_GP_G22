import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/lawyer.dart';
import '../services/api_client.dart';
import 'package:iconsax/iconsax.dart';
import '../services/session.dart';
import '../widgets/admin_bottom_nav.dart';
import 'lawyer_details_for_admin_page.dart';
class DeleteLawyerPage extends StatefulWidget {
  const DeleteLawyerPage({super.key});

  @override
  State<DeleteLawyerPage> createState() => _DeleteLawyerPageState();
}

class _DeleteLawyerPageState extends State<DeleteLawyerPage> {

  //static const String base = 'http://192.168.3.10:8888/mujeer_api';
  static const String base = 'http://10.0.2.2:8888/mujeer_api';
  
  static const String getLawyersUrl = '$base/get_lawyers.php';


  List<Lawyer> _lawyers = [];
  bool _initialLoading = true;
  final Set<int> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    _fetchLawyers();
  }
  void _onLogout() async{
    await Session.clear();
    Navigator.of(context).pushReplacementNamed('/welcome');
  }

//get pending lawyers
  Future<void> _fetchLawyers() async {
    setState(() => _initialLoading = true);
    try {
      final res = await http.get(Uri.parse(getLawyersUrl));
      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }
      final List data = jsonDecode(res.body);
      final list = data.map((e) => Lawyer.fromJson(e as Map<String, dynamic>)).toList();
      setState(() => _lawyers = list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر تحميل قائمة المحامين: $e')),
      );
    } finally {
      if (mounted) setState(() => _initialLoading = false);
    }
  }

  //confirm and delete lawyer
  Future<void> _confirmAndDelete(Lawyer lw) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف "${lw.fullName}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(foregroundColor: Color.fromARGB(255, 9, 44, 36)),
          child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Color.fromARGB(255, 9, 44, 36)),
          child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _deletingIds.add(lw.id));
    try {
      await ApiClient.deleteLawyer(lawyerId: lw.id, base: base);
      setState(() => _lawyers.removeWhere((x) => x.id == lw.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حذف ${lw.fullName} بنجاح')),
        );
      }
    } catch (e) {
      final msg = e.toString();
      final blocked = msg.contains('APPOINT') ||
          msg.contains('appointment') ||
          msg.contains('upcoming') ||
          msg.contains('active');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(blocked
                ? 'لا يمكن الحذف: للمحامي موعد نشط/قادِم.'
                : 'فشل الحذف: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingIds.remove(lw.id));
    }
  }

//lawyers card
Widget _buildLawyerCard(Lawyer lw) {
  final isDeleting = _deletingIds.contains(lw.id);
  return InkWell(
    onTap: () {
      // open details page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminLawyerDetailsPage(
            lawyerId: lw.id, 
          ),
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey.shade200,
            child: ClipOval(
              child: lw.photoUrl.isEmpty
                  ? const Icon(Icons.person)
                  : Image.network(
                      lw.photoUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              lw.fullName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          isDeleting
              ? const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  tooltip: 'حذف',
                  color: Colors.red,
                  icon: const Icon(Iconsax.trash),
                  onPressed: () => _confirmAndDelete(lw),
                ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      backgroundColor: const Color.fromARGB(255, 9, 44, 36),
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: const Text(
        'المحامين',
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
      body: _initialLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchLawyers,
              child: _lawyers.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('لا يوجد محامين حالياً')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _lawyers.length,
                      itemBuilder: (context, i) => _buildLawyerCard(_lawyers[i]),
                    ),
            ),
          bottomNavigationBar: const AdminBottomNav(currentRoute: '/DeleteLawyerPage'),

    );
  }
}
