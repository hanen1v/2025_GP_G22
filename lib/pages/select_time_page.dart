import 'package:flutter/material.dart';
import '../widgets/app_bottom_nav.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'payment_page.dart';

class SelectTimePage extends StatefulWidget {
  final int lawyerId;
  final String caseDetails;
  final String? attachedFileName;
  final double price;

  const SelectTimePage({
    super.key,
    required this.lawyerId,
    required this.caseDetails,
    this.attachedFileName,
    required this.price,
  });

  @override
  State<SelectTimePage> createState() => _SelectTimePageState();
}

class _SelectTimePageState extends State<SelectTimePage> {
  List<dynamic> timeslots = [];
  bool isLoading = true;
  int? selectedSlot;
  double lawyerPrice = 0;

  final Map<String, String> dayArabic = {
    "monday": "الاثنين",
    "tuesday": "الثلاثاء",
    "wednesday": "الأربعاء",
    "thursday": "الخميس",
    "friday": "الجمعة",
    "saturday": "السبت",
    "sunday": "الأحد",
  };

  Future<void> _fetchTimes() async {
    final url = Uri.parse(
        "http://10.0.2.2:8888/mujeer_api/get_timeslots.php?lawyer_id=${widget.lawyerId}");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          timeslots = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchPrice() async {
    final url = Uri.parse(
        "http://10.0.2.2:8888/mujeer_api/get_lawyer_details.php?id=${widget.lawyerId}");

    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        lawyerPrice = data["price"] * 1.0;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchTimes();
    _fetchPrice();
  }

  Widget _buildFab(BuildContext context) => Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 6, 61, 65),
              Color.fromARGB(255, 8, 65, 69)
            ],
          ),
        ),
        child: FloatingActionButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/plus'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      floatingActionButton: _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon:
                    const Icon(Icons.arrow_back_ios_new, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ),


            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "اختر وقت الموعد:",
                        style: TextStyle(
                          color: Color.fromARGB(255, 6, 61, 65),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 25),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            "اليوم",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "الوقت",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Color.fromARGB(255, 6, 61, 65)))
                          : timeslots.isEmpty
                              ? const Text(
                                  "لا توجد مواعيد متاحة",
                                  style: TextStyle(color: Colors.grey),
                                )
                              : Column(
                                  children: List.generate(timeslots.length, (i) {
                                    final slot = timeslots[i];

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedSlot = slot["id"];
                                        });
                                      },
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: selectedSlot ==
                                                    slot["id"]
                                                ? const Color.fromARGB(
                                                    255, 6, 61, 65)
                                                : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),

                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              dayArabic[slot["day"]] ??
                                                  slot["day"],
                                              style: const TextStyle(
                                                  fontSize: 15),
                                            ),
                                            Text(
                                              slot["time"]
                                                  .toString()
                                                  .substring(0, 5),
                                              style: const TextStyle(
                                                  fontSize: 15),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ),

                      const SizedBox(height: 40),

                      // ⬇⬇⬇ الزر الآن داخل الكونتينر مثل صفحة التفاصيل
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 6, 61, 65),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: selectedSlot == null
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PaymentPage(
                                        lawyerId: widget.lawyerId,
                                        timeslotId: selectedSlot!,
                                        price: widget.price,
                                        caseDetails: widget.caseDetails,
                                        attachedFileName:
                                            widget.attachedFileName,
                                      ),
                                    ),
                                  );
                                },
                          child: const Text(
                            "الانتقال إلى الدفع",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar:
          const AppBottomNav(currentRoute: "/select_time"),
    );
  }
}