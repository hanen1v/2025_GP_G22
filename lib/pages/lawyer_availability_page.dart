import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../services/api_client.dart';
import '../services/session.dart';
import '../models/user.dart';
import '../widgets/lawyer_bottom_nav.dart';
class LawyerAvailabilityPage extends StatefulWidget {
  const LawyerAvailabilityPage({super.key});

  @override
  State<LawyerAvailabilityPage> createState() => _LawyerAvailabilityPageState();
}

class _LawyerAvailabilityPageState extends State<LawyerAvailabilityPage> {
  final _formKey = GlobalKey<FormState>();
  User? _user;
  
  // بيانات النموذج
  double _sessionPrice = 0.0;
  final List<String> _selectedDays = [];
  final List<String> _selectedTimes = [];
  
  // حالات التحميل
  bool _loading = false;
  bool _saving = false;
  
  // قوائم الخيارات
  final List<String> _daysOfWeek = [
    'السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'
  ];
  
  final Map<String, List<Map<String, dynamic>>> _timeSlots = {
    'صباح': [
      {'time': '06:00', 'label': '6:00 ص', 'value': '06:00:00'},
      {'time': '07:00', 'label': '7:00 ص', 'value': '07:00:00'},
      {'time': '08:00', 'label': '8:00 ص', 'value': '08:00:00'},
      {'time': '09:00', 'label': '9:00 ص', 'value': '09:00:00'},
      {'time': '10:00', 'label': '10:00 ص', 'value': '10:00:00'},
      {'time': '11:00', 'label': '11:00 ص', 'value': '11:00:00'},
    ],
    'ظهر': [
      {'time': '12:00', 'label': '12:00 م', 'value': '12:00:00'},
      {'time': '13:00', 'label': '1:00 م', 'value': '13:00:00'},
      {'time': '14:00', 'label': '2:00 م', 'value': '14:00:00'},
      {'time': '15:00', 'label': '3:00 م', 'value': '15:00:00'},
      {'time': '16:00', 'label': '4:00 م', 'value': '16:00:00'},
    ],
    'مساء': [
      {'time': '17:00', 'label': '5:00 م', 'value': '17:00:00'},
      {'time': '18:00', 'label': '6:00 م', 'value': '18:00:00'},
      {'time': '19:00', 'label': '7:00 م', 'value': '19:00:00'},
      {'time': '20:00', 'label': '8:00 م', 'value': '20:00:00'},
      {'time': '21:00', 'label': '9:00 م', 'value': '21:00:00'},
      {'time': '22:00', 'label': '10:00 م', 'value': '22:00:00'},
      {'time': '23:00', 'label': '11:00 م', 'value': '23:00:00'},
    ],
  };

  final Map<String, bool> _expandedSections = {
    'صباح': false,
    'ظهر': false,
    'مساء': false,
  };

 @override
void initState() {
  super.initState();
  _initialize();
}

Future<void> _initialize() async {
  await _loadUserData();   // ⚡ انتظري تحميل المستخدم
  await _loadCurrentData(); // ⚡ الآن استدعِ API بعد توفر user.id
}


  Future<void> _loadUserData() async {
    setState(() => _loading = true);
    final user = await Session.getUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _loading = false;
    });
  }

  Future<void> _loadCurrentData() async {
    final user = _user;
    if (user == null) return;

    try {
      // جلب السعر الحالي
      final currentPrice = await ApiClient.getLawyerPrice(user.id);
      
      // جلب الأوقات الحالية
      final availability = await ApiClient.getCurrentAvailability(user.id);
      
      if (!mounted) return;
      
      setState(() {
        _sessionPrice = currentPrice;
        
        // تحميل الأيام والأوقات المحددة مسبقاً
        if (availability['success'] == true) {
          _loadExistingAvailability(availability['data']);
        }
      });
    } catch (e) {
      print('Error loading current data: $e');
    }
  }

  void _loadExistingAvailability(List<dynamic> data) {
    _selectedDays.clear();
    _selectedTimes.clear();
    
    for (final slot in data) {
      final day = slot['day']?.toString() ?? '';
      final time = slot['time']?.toString() ?? '';
      
      if (day.isNotEmpty && !_selectedDays.contains(day)) {
        _selectedDays.add(day);
      }
      
      if (time.isNotEmpty && !_selectedTimes.contains(time)) {
        _selectedTimes.add(time);
      }
    }
  }

  // ✅ هذه هي دالة الحفظ المحدثة التي ذكرتها
  Future<void> _saveAvailability() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty || _selectedTimes.isEmpty) {
      _showError('يرجى اختيار يوم واحد على الأقل ووقت واحد على الأقل');
      return;
    }

    setState(() => _saving = true);
    
    try {
      // 1. تحديث السعر
      final priceUpdated = await ApiClient.updateLawyerPrice(_user!.id, _sessionPrice);
      
      if (!priceUpdated) {
        _showError('حدث خطأ في تحديث السعر');
        return;
      }

      // 2. تحضير بيانات الأوقات
      final List<Map<String, dynamic>> availabilityData = [];
      for (final day in _selectedDays) {
        for (final time in _selectedTimes) {
          availabilityData.add({
            'day': day,
            'time': time,
          });
        }
      }

      // 3. حفظ الأوقات
      final success = await ApiClient.saveAvailability(
        _user!.id,
        availabilityData,
      );
      
      if (!mounted) return;
      
      if (success) {
        _showSuccess('تم حفظ الإتاحة بنجاح');
        // العودة للصفحة السابقة بعد ثانيتين
        // Future.delayed(const Duration(seconds: 2), () {
        //   if (mounted) Navigator.pop(context);
        // });
      } else {
        _showError('حدث خطأ أثناء حفظ الأوقات');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('حدث خطأ في الاتصال: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: const Color(0xFF0B5345),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildPriceField() {
  return Card(
    color: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(12), // خففت الـ padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.money, color: Color(0xFF0B5345), size: 20), // صغرت الأيقونة
              const SizedBox(width: 6),
              const Text(
                'سعر الجلسة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  fontSize: 14, // صغرت الخط
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // خففت المسافة
          TextFormField(
            keyboardType: TextInputType.number,
            initialValue: _sessionPrice > 0 ? _sessionPrice.toString() : '',
            decoration: InputDecoration(
              hintText: 'أدخل سعر الجلسة بالريال',
              hintStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF0B5345)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12), // خففت الـ padding
            ),
            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
            onChanged: (value) {
              setState(() {
                _sessionPrice = double.tryParse(value) ?? 0.0;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال سعر الجلسة';
              }
              if (double.tryParse(value) == null) {
                return 'يرجى إدخال سعر صحيح';
              }
              return null;
            },
          ),
        ],
      ),
    ),
  );
}
  Widget _buildDaysSection() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.calendar, color: Color(0xFF0B5345)),
                const SizedBox(width: 8),
                const Text(
                  'أيام الإتاحة',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _daysOfWeek.map((day) {
                final isSelected = _selectedDays.contains(day);
                return FilterChip(
                  label: Text(day, style: const TextStyle(fontFamily: 'Tajawal')),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDays.add(day);
                      } else {
                        _selectedDays.remove(day);
                      }
                    });
                  },
                  selectedColor: const Color(0xFF0B5345).withOpacity(0.1),
                  checkmarkColor: const Color(0xFF0B5345),
                  backgroundColor: Colors.grey[100],
                  labelStyle: TextStyle(
                    color: isSelected ? const Color(0xFF0B5345) : Colors.black,
                    fontFamily: 'Tajawal',
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSection(String period, List<Map<String, dynamic>> times) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(
          period == 'صباح' ? Iconsax.sun_1 :
          period == 'ظهر' ? Iconsax.sun_1 :
          Iconsax.moon,
          color: const Color(0xFF0B5345),
        ),
        title: Text(
          period,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        initiallyExpanded: _expandedSections[period] ?? false,
        onExpansionChanged: (expanded) {
          setState(() {
            _expandedSections[period] = expanded;
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: times.map((timeSlot) {
                final isSelected = _selectedTimes.contains(timeSlot['value']);
                return FilterChip(
                  label: Text(
                    timeSlot['label'],
                    style: const TextStyle(fontFamily: 'Tajawal'),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTimes.add(timeSlot['value']);
                      } else {
                        _selectedTimes.remove(timeSlot['value']);
                      }
                    });
                  },
                  selectedColor: const Color(0xFF0B5345).withOpacity(0.1),
                  checkmarkColor: const Color(0xFF0B5345),
                  backgroundColor: Colors.grey[100],
                  labelStyle: TextStyle(
                    color: isSelected ? const Color(0xFF0B5345) : Colors.black,
                    fontFamily: 'Tajawal',
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  if (_loading) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF0B5345)),
      ),
    );
  }

  return Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(
        title: const Text(
          'تحديد الإتاحة',
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: 80, // مساحة إضافية من الأسفل
          ),
          child: Column( // أضف Column هنا
            children: [
              _buildPriceField(),
              const SizedBox(height: 16),
              _buildDaysSection(),
              const SizedBox(height: 16),
              ..._timeSlots.entries.map((entry) => 
                Column(
                  children: [
                    _buildTimeSection(entry.key, entry.value),
                    const SizedBox(height: 12),
                  ],
                )
              ),
              const SizedBox(height: 24),
              Container( // أضف Container حول الزر
                padding: const EdgeInsets.only(bottom: 20),
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveAvailability,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B5345),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'حفظ الإتاحة',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Tajawal',
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Iconsax.save_2, color: Colors.white),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const LawyerBottomNav(currentRoute: '/lawyer/availability'),
    ),
  );
}
}
