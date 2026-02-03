import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:table_calendar/table_calendar.dart';
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
  
  double _sessionPrice = 0.0;
  final List<DateTime> _selectedDates = [];
  final List<String> _selectedTimes = [];
  String? _priceMessage;
  bool _priceSaved = false;
  bool _isSavingPrice = false;
  bool _loading = false;
  bool _saving = false;
  bool _deleting = false;
  
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Map<String, dynamic>> _unbookedSlots = [];
  
  final Map<String, List<Map<String, dynamic>>> _timeSlots = {
    'صباح': [
      {'time': '06:00', 'label': '6:00', 'value': '06:00:00'},
      {'time': '06:20', 'label': '6:20', 'value': '06:20:00'},
      {'time': '06:40', 'label': '6:40', 'value': '06:40:00'},
      {'time': '07:00', 'label': '7:00', 'value': '07:00:00'},
      {'time': '07:20', 'label': '7:20', 'value': '07:20:00'},
      {'time': '07:40', 'label': '7:40', 'value': '07:40:00'},
      {'time': '08:00', 'label': '8:00', 'value': '08:00:00'},
      {'time': '08:20', 'label': '8:20', 'value': '08:20:00'},
      {'time': '08:40', 'label': '8:40', 'value': '08:40:00'},
      {'time': '09:00', 'label': '9:00', 'value': '09:00:00'},
      {'time': '09:20', 'label': '9:20', 'value': '09:20:00'},
      {'time': '09:40', 'label': '9:40', 'value': '09:40:00'},
      {'time': '10:00', 'label': '10:00', 'value': '10:00:00'},
      {'time': '10:20', 'label': '10:20', 'value': '10:20:00'},
      {'time': '10:40', 'label': '10:40', 'value': '10:40:00'},
      {'time': '11:00', 'label': '11:00', 'value': '11:00:00'},
      {'time': '11:20', 'label': '11:20', 'value': '11:20:00'},
      {'time': '11:40', 'label': '11:40', 'value': '11:40:00'},
    ],
    'ظهر': [
      {'time': '12:00', 'label': '12:00', 'value': '12:00:00'},
      {'time': '12:20', 'label': '12:20', 'value': '12:20:00'},
      {'time': '12:40', 'label': '12:40', 'value': '12:40:00'},
      {'time': '13:00', 'label': '13:00', 'value': '13:00:00'},
      {'time': '13:20', 'label': '13:20', 'value': '13:20:00'},
      {'time': '13:40', 'label': '13:40', 'value': '13:40:00'},
      {'time': '14:00', 'label': '14:00', 'value': '14:00:00'},
      {'time': '14:20', 'label': '14:20', 'value': '14:20:00'},
      {'time': '14:40', 'label': '14:40', 'value': '14:40:00'},
      {'time': '15:00', 'label': '15:00', 'value': '15:00:00'},
      {'time': '15:20', 'label': '15:20', 'value': '15:20:00'},
      {'time': '15:40', 'label': '15:40', 'value': '15:40:00'},
      {'time': '16:00', 'label': '16:00', 'value': '16:00:00'},
      {'time': '16:20', 'label': '16:20', 'value': '16:20:00'},
      {'time': '16:40', 'label': '16:40', 'value': '16:40:00'},
    ],
    'مساء': [
      {'time': '17:00', 'label': '17:00', 'value': '17:00:00'},
      {'time': '17:20', 'label': '17:20', 'value': '17:20:00'},
      {'time': '17:40', 'label': '17:40', 'value': '17:40:00'},
      {'time': '18:00', 'label': '18:00', 'value': '18:00:00'},
      {'time': '18:20', 'label': '18:20', 'value': '18:20:00'},
      {'time': '18:40', 'label': '18:40', 'value': '18:40:00'},
      {'time': '19:00', 'label': '19:00', 'value': '19:00:00'},
      {'time': '19:20', 'label': '19:20', 'value': '19:20:00'},
      {'time': '19:40', 'label': '19:40', 'value': '19:40:00'},
      {'time': '20:00', 'label': '20:00', 'value': '20:00:00'},
      {'time': '20:20', 'label': '20:20', 'value': '20:20:00'},
      {'time': '20:40', 'label': '20:40', 'value': '20:40:00'},
      {'time': '21:00', 'label': '21:00', 'value': '21:00:00'},
      {'time': '21:20', 'label': '21:20', 'value': '21:20:00'},
      {'time': '21:40', 'label': '21:40', 'value': '21:40:00'},
      {'time': '22:00', 'label': '22:00', 'value': '22:00:00'},
      {'time': '22:20', 'label': '22:20', 'value': '22:20:00'},
      {'time': '22:40', 'label': '22:40', 'value': '22:40:00'},
      {'time': '23:00', 'label': '23:00', 'value': '23:00:00'},
      {'time': '23:20', 'label': '23:20', 'value': '23:20:00'},
      {'time': '23:40', 'label': '23:40', 'value': '23:40:00'},
    ],
  };

  final Map<String, bool> _expandedSections = {
    'صباح': false,
    'ظهر': false,
    'مساء': false,
  };

  final List<Map<String, dynamic>> _selectedSlotsToDelete = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadUserData();
    await _loadCurrentData();
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
      final currentPrice = await ApiClient.getLawyerPrice(user.id);
      final availability = await ApiClient.getCurrentAvailability(user.id);
      final unbookedAvailability = await ApiClient.getUnbookedAvailability(user.id);
      
      if (!mounted) return;
      
      setState(() {
        _sessionPrice = currentPrice;
        
        if (availability['success'] == true) {
          _loadExistingAvailability(availability['data']);
        }
        
        // تصحيح: إزالة التحقق من is_booked لأن API لا يعيده
        if (unbookedAvailability['success'] == true) {
          // API يرجع الأوقات غير المحجوزة فقط
          _unbookedSlots = (unbookedAvailability['data'] as List)
              .map((slot) => ({
                    'day': slot['day']?.toString() ?? '',
                    'time': slot['time']?.toString() ?? '',
                    'formattedDate': _formatDate(slot['day']?.toString() ?? ''),
                    'formattedTime': _formatTime(slot['time']?.toString() ?? ''),
                  }))
              .toList();
        } else {
          _unbookedSlots = [];
        }
        
        _selectedSlotsToDelete.clear();
      });
    } catch (e) {
      print('Error loading current data: $e');
      setState(() {
        _unbookedSlots = [];
        _selectedSlotsToDelete.clear();
      });
    }
  }

  void _loadExistingAvailability(List<dynamic> data) {
    _selectedDates.clear();
    _selectedTimes.clear();
    
    for (final slot in data) {
      final day = slot['day']?.toString() ?? '';
      final time = slot['time']?.toString() ?? '';
      
      if (day.isNotEmpty) {
        try {
          final date = DateTime.parse(day);
          if (!_selectedDates.any((d) => _isSameDay(d, date))) {
            _selectedDates.add(date);
          }
        } catch (e) {
          print('Error parsing date: $day');
        }
      }
      
      if (time.isNotEmpty && !_selectedTimes.contains(time)) {
        _selectedTimes.add(time);
      }
    }
  }

  void _loadUnbookedSlots(List<dynamic> data) {
    _unbookedSlots.clear();
    
    for (final slot in data) {
      final day = slot['day']?.toString() ?? '';
      final time = slot['time']?.toString() ?? '';
      
      if (day.isNotEmpty && time.isNotEmpty) {
        _unbookedSlots.add({
          'day': day,
          'time': time,
          'formattedDate': _formatDate(day),
          'formattedTime': _formatTime(time),
        });
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}/${date.month}/${date.day}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(String timeString) {
    try {
      final timeParts = timeString.split(':');
      if (timeParts.length >= 2) {
        final hour = int.parse(timeParts[0]);
        final minute = timeParts[1];
        
        if (hour < 12) {
          return '${hour == 0 ? 12 : hour}:${minute} ص';
        } else {
          return '${hour == 12 ? 12 : hour - 12}:${minute} م';
        }
      }
      return timeString;
    } catch (e) {
      return timeString;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _saveAvailability() async {
  if (!_formKey.currentState!.validate()) return;
  if (_selectedDates.isEmpty || _selectedTimes.isEmpty) {
    _showError('يرجى اختيار يوم واحد على الأقل ووقت واحد على الأقل');
    return;
  }

  // تأكيد على السعر
  if (_sessionPrice <= 0) {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تنبيه', style: TextStyle(fontFamily: 'Tajawal')),
        content: const Text(
          'لم يتم تحديد سعر للجلسة. هل تريد المتابعة بدون تحديد سعر؟',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('متابعة', style: TextStyle(fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
    
    if (confirm != true) {
      return;
    }
  }

  setState(() => _saving = true);
  
  try {
    // ✅ حفظ السعر أولاً (حتى لو كان صفراً)
    if (_sessionPrice > 0) {
      await ApiClient.updateLawyerPrice(_user!.id, _sessionPrice);
    }

    final List<Map<String, dynamic>> availabilityData = [];
    for (final date in _selectedDates) {
      for (final time in _selectedTimes) {
        availabilityData.add({
          'day': date.toIso8601String().split('T')[0],
          'time': time,
        });
      }
    }

    final success = await ApiClient.saveAvailability(
      _user!.id,
      availabilityData,
    );
    
    if (!mounted) return;
    
    if (success) {
      _showSuccess('تم حفظ الإتاحة والسعر بنجاح');
      await _loadCurrentData();
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
Future<void> _savePriceOnly() async {
  if (_sessionPrice <= 0) {
    _showError('يرجى إدخال سعر صحيح');
    return;
  }

  setState(() {
    _isSavingPrice = true;
    _priceMessage = null;
    _priceSaved = false;
  });

  try {
    final priceUpdated = await ApiClient.updateLawyerPrice(_user!.id, _sessionPrice);
    
    if (!mounted) return;
    
    if (priceUpdated) {
      setState(() {
        _priceMessage = '✅ تم حفظ السعر بنجاح';
        _priceSaved = true;
      });
      
      // إخفاء الرسالة بعد 3 ثواني
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _priceMessage = null;
          });
        }
      });
    } else {
      setState(() {
        _priceMessage = '❌ فشل في حفظ السعر، حاول مرة أخرى';
        _priceSaved = false;
      });
    }
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _priceMessage = '❌ خطأ في الاتصال: $e';
      _priceSaved = false;
    });
  } finally {
    if (mounted) {
      setState(() => _isSavingPrice = false);
    }
  }
}
  /// حذف الأوقات المحددة مع التحقق المسبق من المحجوزة
  Future<void> _deleteSelectedSlots() async {
    if (_selectedSlotsToDelete.isEmpty) {
      _showError('يرجى اختيار أوقات للحذف');
      return;
    }

    // التحقق من الأوقات المحجوزة أولاً
    try {
      final checkResult = await ApiClient.checkBookedSlots(
        _user!.id,
        _selectedSlotsToDelete,
      );
      
      if (checkResult['success'] == true) {
        final bookedSlots = checkResult['booked_slots'] as List;
        
        if (bookedSlots.isNotEmpty) {
          final bookedCount = bookedSlots.length;
          final remainingCount = (checkResult['unbooked_slots'] as List).length;
          
          final shouldContinue = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('تحذير', style: TextStyle(fontFamily: 'Tajawal')),
              content: Text(
                '$bookedCount من الأوقات المختارة محجوزة.\n'
                'فقط $remainingCount وقت يمكن حذفه.\n'
                'هل تريد المتابعة؟',
                style: const TextStyle(fontFamily: 'Tajawal'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('متابعة', style: TextStyle(fontFamily: 'Tajawal')),
                ),
              ],
            ),
          );
          
          if (shouldContinue != true) {
            _selectedSlotsToDelete.clear();
            return;
          }
          
          // تحديث القائمة بالأوقات القابلة للحذف فقط
          setState(() {
            _selectedSlotsToDelete.clear();
            _selectedSlotsToDelete.addAll(
              (checkResult['unbooked_slots'] as List).cast<Map<String, dynamic>>()
            );
          });
          
          if (_selectedSlotsToDelete.isEmpty) {
            _showError('لا توجد أوقات قابلة للحذف');
            return;
          }
        }
      }
    } catch (e) {
      print('Error checking booked slots: $e');
      // استمر في العملية رغم الخطأ
    }

    final confirmed = await _showDeleteConfirmationDialog();
    if (!confirmed) return;

    setState(() => _deleting = true);
    
    try {
      final success = await ApiClient.deleteSelectedAvailability(
        _user!.id,
        _selectedSlotsToDelete,
      );
      
      if (!mounted) return;
      
      if (success) {
        _showSuccess('تم حذف الأوقات المحددة بنجاح');
        await _loadCurrentData();
        _selectedSlotsToDelete.clear();
      } else {
        _showError('حدث خطأ أثناء حذف الأوقات');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('حدث خطأ في الاتصال: $e');
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'تأكيد الحذف',
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من حذف ${_selectedSlotsToDelete.length} وقت محدد؟',
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'حذف',
              style: TextStyle(fontFamily: 'Tajawal', color: Colors.white),
            ),
          ),
        ],
      ),
    );
    
    return result ?? false;
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Iconsax.money, color: Color(0xFF0B5345)),
              SizedBox(width: 8),
              Text(
                'سعر الجلسة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          TextFormField(
            keyboardType: TextInputType.number,
            initialValue: _sessionPrice > 0 ? _sessionPrice.toString() : '',
            decoration: InputDecoration(
              hintText: 'أدخل سعر الجلسة بالريال',
              hintStyle: const TextStyle(fontFamily: 'Tajawal'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF0B5345)),
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Text(
                  'ر.س',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Color(0xFF0B5345),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            style: const TextStyle(fontFamily: 'Tajawal'),
            onChanged: (value) {
              setState(() {
                _sessionPrice = double.tryParse(value) ?? 0.0;
              });
            },
          ),

          const SizedBox(height: 16),

          /// زر حفظ السعر (نفس تنسيق حفظ الإتاحة)
          ElevatedButton(
            onPressed: _isSavingPrice
                ? null
                : () async {
                    if (_sessionPrice <= 0) {
                      _showError('يرجى إدخال سعر صحيح');
                      return;
                    }
                    await _savePriceOnly();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B5345),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: _isSavingPrice
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
                        'حفظ السعر',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Iconsax.save_2, color: Colors.white),
                    ],
                  ),
          ),

          if (_priceMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _priceMessage!,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                color: _priceSaved ? Colors.green : Colors.red,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}


  Widget _buildCalendarSection() {
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
                const Icon(Iconsax.calendar_1, color: Color(0xFF0B5345)),
                const SizedBox(width: 8),
                const Text(
                  'اختر الأيام المتاحة',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (_selectedDates.isNotEmpty)
                  Text(
                    '${_selectedDates.length} يوم مختار',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      color: Color(0xFF0B5345),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime(DateTime.now().year + 1, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return _selectedDates.any((selectedDate) => _isSameDay(selectedDate, day));
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                  _selectedDay = selectedDay;
                  
                  if (_selectedDates.any((date) => _isSameDay(date, selectedDay))) {
                    _selectedDates.removeWhere((date) => _isSameDay(date, selectedDay));
                  } else {
                    _selectedDates.add(selectedDay);
                  }
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: const Color(0xFF0B5345),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: const Color(0xFF0B5345).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: const Color(0xFF0B5345),
                  shape: BoxShape.circle,
                ),
                outsideDaysVisible: false,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                leftChevronIcon: const Icon(Iconsax.arrow_right_3, color: Color(0xFF0B5345)),
                rightChevronIcon: const Icon(Iconsax.arrow_left_2, color: Color(0xFF0B5345)),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                weekendStyle: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: Colors.red),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  return Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _selectedDates.any((date) => _isSameDay(date, day))
                          ? const Color(0xFF0B5345)
                          : Colors.transparent,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          color: _selectedDates.any((date) => _isSameDay(date, day))
                              ? Colors.white
                              : Colors.black,
                          fontWeight: _isSameDay(day, DateTime.now())
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedDates.isNotEmpty) ...[
              const Divider(),
              const Text(
                'الأيام المختارة:',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _selectedDates.map((date) {
                  return Chip(
                    label: Text(
                      '${date.year}/${date.month}/${date.day}',
                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                    ),
                    backgroundColor: const Color(0xFF0B5345).withOpacity(0.1),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() {
                        _selectedDates.remove(date);
                      });
                    },
                  );
                }).toList(),
              ),
            ],
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

  Widget _buildUnbookedSlotsSection() {
    if (_unbookedSlots.isEmpty) {
      return Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              'لا توجد أوقات غير محجوزة حالياً',
              style: TextStyle(
                fontFamily: 'Tajawal',
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );
    }

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
                const Icon(Iconsax.calendar_remove, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'الأوقات غير المحجوزة',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
                const Spacer(),
                if (_selectedSlotsToDelete.isNotEmpty)
                  Text(
                    '${_selectedSlotsToDelete.length} مختار',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'اختر الأوقات التي تريد حذفها:',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _unbookedSlots.map((slot) {
                final isSelected = _selectedSlotsToDelete.any((selected) => 
                  selected['day'] == slot['day'] && selected['time'] == slot['time']
                );
                
                return FilterChip(
                  label: Text(
                    '${slot['formattedDate']} - ${slot['formattedTime']}',
                    style: const TextStyle(fontFamily: 'Tajawal'),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSlotsToDelete.add({
                          'day': slot['day'],
                          'time': slot['time'],
                        });
                      } else {
                        _selectedSlotsToDelete.removeWhere((selected) => 
                          selected['day'] == slot['day'] && selected['time'] == slot['time']
                        );
                      }
                    });
                  },
                  selectedColor: Colors.red.withOpacity(0.1),
                  checkmarkColor: Colors.red,
                  backgroundColor: Colors.grey[100],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.red : Colors.black,
                    fontFamily: 'Tajawal',
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (_selectedSlotsToDelete.isNotEmpty)
              ElevatedButton(
                onPressed: _deleting ? null : _deleteSelectedSlots,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(double.infinity, 45),
                ),
                child: _deleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
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
                            'حذف الأوقات المحددة',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tajawal',
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Iconsax.trash, color: Colors.white, size: 18),
                        ],
                      ),
              ),
          ],
        ),
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
              bottom: 80,
            ),
            child: Column(
              children: [
                _buildPriceField(),
                const SizedBox(height: 16),
                _buildCalendarSection(),
                const SizedBox(height: 16),
                ..._timeSlots.entries.map((entry) => 
                  Column(
                    children: [
                      _buildTimeSection(entry.key, entry.value),
                      const SizedBox(height: 12),
                    ],
                  )
                ),
                const SizedBox(height: 16),
                
                _buildUnbookedSlotsSection(),
                
                const SizedBox(height: 24),
                
                Container(
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