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
  
  bool _loading = false;
  bool _saving = false;
  bool _deleting = false;
  
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Map<String, dynamic>> _unbookedSlots = [];
  
  final Map<String, List<Map<String, dynamic>>> _timeSlots = {
    'صباح': [
      {'time': '06:00', 'label': '6:00 ص', 'value': '06:00:00'},
      {'time': '06:30', 'label': '6:30 ص', 'value': '06:30:00'},
      {'time': '07:00', 'label': '7:00 ص', 'value': '07:00:00'},
      {'time': '07:30', 'label': '7:30 ص', 'value': '07:30:00'},
      {'time': '08:00', 'label': '8:00 ص', 'value': '08:00:00'},
      {'time': '08:30', 'label': '8:30 ص', 'value': '08:30:00'},
      {'time': '09:00', 'label': '9:00 ص', 'value': '09:00:00'},
      {'time': '09:30', 'label': '9:30 ص', 'value': '09:30:00'},
      {'time': '10:00', 'label': '10:00 ص', 'value': '10:00:00'},
      {'time': '10:30', 'label': '10:30 ص', 'value': '10:30:00'},
      {'time': '11:00', 'label': '11:00 ص', 'value': '11:00:00'},
      {'time': '11:30', 'label': '11:30 ص', 'value': '11:30:00'},
    ],
    'ظهر': [
      {'time': '12:00', 'label': '12:00 م', 'value': '12:00:00'},
      {'time': '12:30', 'label': '12:30 م', 'value': '12:30:00'},
      {'time': '13:00', 'label': '1:00 م', 'value': '13:00:00'},
      {'time': '13:30', 'label': '1:30 م', 'value': '13:30:00'},
      {'time': '14:00', 'label': '2:00 م', 'value': '14:00:00'},
      {'time': '14:30', 'label': '2:30 م', 'value': '14:30:00'},
      {'time': '15:00', 'label': '3:00 م', 'value': '15:00:00'},
      {'time': '15:30', 'label': '3:30 م', 'value': '15:30:00'},
      {'time': '16:00', 'label': '4:00 م', 'value': '16:00:00'},
      {'time': '16:30', 'label': '4:30 م', 'value': '16:30:00'},
    ],
    'مساء': [
      {'time': '17:00', 'label': '5:00 م', 'value': '17:00:00'},
      {'time': '17:30', 'label': '5:30 م', 'value': '17:30:00'},
      {'time': '18:00', 'label': '6:00 م', 'value': '18:00:00'},
      {'time': '18:30', 'label': '6:30 م', 'value': '18:30:00'},
      {'time': '19:00', 'label': '7:00 م', 'value': '19:00:00'},
      {'time': '19:30', 'label': '7:30 م', 'value': '19:30:00'},
      {'time': '20:00', 'label': '8:00 م', 'value': '20:00:00'},
      {'time': '20:30', 'label': '8:30 م', 'value': '20:30:00'},
      {'time': '21:00', 'label': '9:00 م', 'value': '21:00:00'},
      {'time': '21:30', 'label': '9:30 م', 'value': '21:30:00'},
      {'time': '22:00', 'label': '10:00 م', 'value': '22:00:00'},
      {'time': '22:30', 'label': '10:30 م', 'value': '22:30:00'},
      {'time': '23:00', 'label': '11:00 م', 'value': '23:00:00'},
      {'time': '23:30', 'label': '11:30 م', 'value': '23:30:00'},
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
/// Initializes the page by loading user data and current availability
  Future<void> _initialize() async {
    await _loadUserData();
    await _loadCurrentData();
  }
  /// Fetches current price, availability, and unbooked slots from API
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
        
        if (unbookedAvailability['success'] == true) {
          _loadUnbookedSlots(unbookedAvailability['data']);
        }
      });
    } catch (e) {
      print('Error loading current data: $e');
    }
  }
  /// Parses and loads existing availability data into selected dates and times
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
  /// Loads and formats unbooked time slots for display
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
  /// Formats date string to localized format (YYYY/MM/DD)
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}/${date.month}/${date.day}';
    } catch (e) {
      return dateString;
    }
  }
  /// Converts 24-hour time format to 12-hour format with AM/PM in Arabic
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
  /// Utility function to check if two DateTime objects represent the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  /// Main function to save lawyer's availability including price and time slots
  Future<void> _saveAvailability() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDates.isEmpty || _selectedTimes.isEmpty) {
      _showError('يرجى اختيار يوم واحد على الأقل ووقت واحد على الأقل');
      return;
    }

    setState(() => _saving = true);
    
    try {
      // First update the session price
      final priceUpdated = await ApiClient.updateLawyerPrice(_user!.id, _sessionPrice);
      
      if (!priceUpdated) {
        _showError('حدث خطأ في تحديث السعر');
        return;
      }
// Prepare availability data by combining selected dates and times
      final List<Map<String, dynamic>> availabilityData = [];
      for (final date in _selectedDates) {
        for (final time in _selectedTimes) {
          availabilityData.add({
            'day': date.toIso8601String().split('T')[0], // Format: YYYY-MM-DD
            'time': time, // Format: HH:MM:SS
          });
        }
      }
// Save the combined availability data
      final success = await ApiClient.saveAvailability(
        _user!.id,
        availabilityData,
      );
      
      if (!mounted) return;
      
      if (success) {
        _showSuccess('تم حفظ الإتاحة بنجاح');
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
/// Deletes selected unbooked time slots by saving only the remaining slots
  Future<void> _deleteSelectedSlots() async {
    if (_selectedSlotsToDelete.isEmpty) {
      _showError('يرجى اختيار أوقات للحذف');
      return;
    }

    final confirmed = await _showDeleteConfirmationDialog();
    if (!confirmed) return;

    setState(() => _deleting = true);
    
    try {
      // Get current availability to determine which slots to keep
      final currentAvailability = await ApiClient.getCurrentAvailability(_user!.id);
      
      if (!currentAvailability['success']) {
        throw Exception('فشل في جلب الأوقات الحالية');
      }
// Filter out the slots marked for deletion
      final List<Map<String, dynamic>> remainingSlots = [];
      for (final slot in currentAvailability['data']) {
        final shouldKeep = !_selectedSlotsToDelete.any((selected) => 
          selected['day'] == slot['day'] && selected['time'] == slot['time']
        );
        
        if (shouldKeep) {
          remainingSlots.add({
            'day': slot['day'],
            'time': slot['time'],
          });
        }
      }

      final success = await ApiClient.saveAvailability(
        _user!.id,
        remainingSlots,
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
/// Shows confirmation dialog before deleting selected time slots
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
/// Displays error message in a snackbar
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
/// Displays success message in a snackbar
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: const Color(0xFF0B5345),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
/// Builds the session price input field
  Widget _buildPriceField() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.money, color: Color(0xFF0B5345), size: 20),
                const SizedBox(width: 6),
                const Text(
                  'سعر الجلسة',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
/// Builds the calendar section for selecting available dates
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
/// Builds expandable time section for morning, afternoon, and evening slots
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
/// Builds the section for managing unbooked time slots with delete functionality
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