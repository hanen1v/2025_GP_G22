import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/app_bottom_nav.dart';
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
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<dynamic> allSlots = [];
  List<dynamic> daySlots = [];
  bool isLoading = true;
  int? selectedSlot;


  final Color mainColor = const Color.fromARGB(255, 6, 61, 65);

  @override
  void initState() {
    super.initState();
    _fetchTimes();
  }

  Future<void> _fetchTimes() async {
    final url = Uri.parse(
        "http://10.0.2.2:8888/mujeer_api/get_timeslots.php?lawyer_id=${widget.lawyerId}");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        allSlots = jsonDecode(response.body);

        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _filterByDay(DateTime date) {
    String selectedDate = date.toIso8601String().substring(0, 10);

    setState(() {
      _selectedDay = date;
      daySlots = allSlots.where((s) {
        return s["time"].substring(0, 10) == selectedDate &&
            DateTime.parse(s["time"]).isAfter(DateTime.now());
      }).toList();
    });
  }

  bool _hasSlot(DateTime day) {
    String d = day.toIso8601String().substring(0, 10);
    return allSlots.any((s) => s["time"].substring(0, 10) == d);
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
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.grey),
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
                        "اختر التاريخ والوقت:",
                        style: TextStyle(
                          color: Color.fromARGB(255, 6, 61, 65),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 25),

                      isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Color.fromARGB(255, 6, 61, 65)))
                          :

                      TableCalendar(
                        locale: "ar",
                        firstDay: DateTime.now(),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),

                        headerStyle: HeaderStyle(
                          titleCentered: true,
                          formatButtonVisible: false,
                          titleTextFormatter: (date, locale) =>
                              "${_monthName(date.month)} ${date.year}",
                          titleTextStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 6, 61, 65),
                          ),
                          leftChevronIcon: Icon(Icons.arrow_back_ios,
                              color: mainColor, size: 18),
                          rightChevronIcon: Icon(Icons.arrow_forward_ios,
                              color: mainColor, size: 18),
                        ),

                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: mainColor,
                            shape: BoxShape.circle,
                          ),
                          markerDecoration: BoxDecoration(
                            color: mainColor,
                            shape: BoxShape.circle,
                          ),
                        ),

                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, date, events) {
                            if (_hasSlot(date)) {
                              return Positioned(
                                bottom: 4,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: mainColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            }
                            return null;
                          },
                        ),

                        onDaySelected: (selected, focused) {
                          _filterByDay(selected);
                        },

                      ),

                      const SizedBox(height: 30),

                      const Text(
                        "الأوقات المتاحة:",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),




                      const SizedBox(height: 15),

                      daySlots.isEmpty
                          ? const Text("لا يوجد أوقات متاحة في هذا اليوم",
                              style: TextStyle(color: Colors.grey))
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: daySlots.map((s) {
                                String hour =
                                    s["time"].substring(11, 16);

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedSlot = s["id"];
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selectedSlot == s["id"]
                                            ? mainColor
                                            : Colors.grey[300]!,
                                        width: 2,
                                      ),
                                    ),
                                    child: Text(
                                      hour,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: selectedSlot == s["id"]
                                            ? mainColor
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                      SizedBox(height: 6),

Text(
  " مدة الموعد 15 دقيقة",
  style: TextStyle(
    fontSize: 14,
    color: Color.fromARGB(255, 6, 61, 65), 
    fontWeight: FontWeight.w500,
  ),
),
                      const SizedBox(height: 40),

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

      bottomNavigationBar: const AppBottomNav(currentRoute: "/select_time"),
    );
  }

  String _monthName(int m) {
    const names = [
      "",
      "يناير",
      "فبراير",
      "مارس",
      "أبريل",
      "مايو",
      "يونيو",
      "يوليو",
      "أغسطس",
      "سبتمبر",
      "أكتوبر",
      "نوفمبر",
      "ديسمبر"
    ];
    return names[m];
  }
}