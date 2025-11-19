import 'package:flutter/material.dart';
import '../widgets/app_bottom_nav.dart';
import 'package:iconsax/iconsax.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  int selectedSort = -1;
  String searchQuery = '';


  final List<String> sortOptions = [
    'السعر من الأقل إلى الأعلى',
    'السعر من الأعلى إلى الأقل',
    'من الأعلى خبرة',
    'من الأعلى تقييم',
  ];


Future<void> _fetchLawyers() async {
  final url = Uri.parse('http://192.168.3.10:8888/mujeer_api/get_lawyers.php');
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        lawyers = List<Map<String, dynamic>>.from(data);
        filteredLawyers = List.from(lawyers);
      });
    } else {
      throw Exception('فشل تحميل البيانات');
    }
  } catch (e) {
    print('خطأ أثناء جلب البيانات: $e');
  }
}





List<Map<String, dynamic>> lawyers = [];

  List<Map<String, dynamic>> filteredLawyers = [];

  //  الفلاتر
  List<String> selectedAcademic = [];
  List<String> selectedDegree = [];
  List<String> selectedSpeciality = [];

  final List<String> academicOptions = ['القانون', 'الشريعة'];
  final List<String> degreeOptions = ['دبلوم','بكالوريوس', 'ماجستير', 'دكتوراه'];
  final List<String> specialityOptions = [
    'القضايا الجنائية',
    'القضايا الأسرية',
    'القضايا التجارية',
    'القضايا العمالية',
    'القضايا العقارية',
    'القضايا الإدارية',
    'القضايا المالية',
    'قضايا الأحوال الشخصية',
  ];

  @override
  void initState() {
    super.initState();
      _fetchLawyers();
  
  }



  //  البحث
  void _searchLawyers(String query) {
    setState(() {
      searchQuery = query.trim();
      filteredLawyers = lawyers.where((lawyer) {
        final name = lawyer['name'].toString();
        return name.contains(query);
      }).toList();
      _applySorting();
    });
  }

  //  الفرز
  void _applySorting() {
    setState(() {
      switch (selectedSort) {
        case 0:
          filteredLawyers.sort((a, b) => a['price'].compareTo(b['price']));
          break;
        case 1:
          filteredLawyers.sort((a, b) => b['price'].compareTo(a['price']));
          break;
        case 2:
          filteredLawyers.sort((a, b) {
            int getYears(String exp) {
              final match = RegExp(r'(\d+)').firstMatch(exp);
              return match != null ? int.parse(match.group(0)!) : 0;
            }

            return getYears(b['experience'])
                .compareTo(getYears(a['experience']));
          });
          break;
        case 3:
          filteredLawyers.sort((a, b) => b['rating'].compareTo(a['rating']));
          break;
        default:
          filteredLawyers = List.from(filteredLawyers);
      }
    });
  }

  //   الفلاتر

  void _applyFilters() {
  setState(() {
    filteredLawyers = lawyers.where((lawyer) {
      final academic = (lawyer['academic'] ?? '').toString().trim().toLowerCase();
      final degree = (lawyer['degree'] ?? '').toString().trim().toLowerCase();
      final speciality = (lawyer['speciality'] ?? '').toString().trim().toLowerCase();

      final matchAcademic = selectedAcademic.isEmpty ||
          selectedAcademic.any((item) => academic.contains(item.trim().toLowerCase()));
      final matchDegree = selectedDegree.isEmpty ||
          selectedDegree.any((item) => degree.contains(item.trim().toLowerCase()));
      final matchSpeciality = selectedSpeciality.isEmpty ||
          selectedSpeciality.any((item) => speciality.contains(item.trim().toLowerCase()));

      return matchAcademic && matchDegree && matchSpeciality;
    }).toList();
  });

  Navigator.pop(context);

  if (filteredLawyers.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('لا يوجد محامي مطابق لخيارات التصفية المختارة'),
        backgroundColor: Color.fromARGB(255, 6, 61, 65),
      ),
    );
  }
}

  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          //  أعلى الصفحة
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
            child: Column(
              children: [
                //   Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: TextField(
                    textDirection: TextDirection.rtl,
                    onChanged: _searchLawyers,
                    decoration: InputDecoration(
                      hintText: 'البحث عن محامي',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: const Icon(Iconsax.search_normal, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                //  الفلتر والفرز
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // زر الفلتر
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: GestureDetector(
                          onTap: () => _showFilterSheet(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.filter_list, color: Colors.grey, size: 22),
                                SizedBox(width: 6),
                                Text('تصفية', style: TextStyle(fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // أزرار الفرز
                      ...List.generate(sortOptions.length, (index) {
                        final isSelected = selectedSort == index;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: GestureDetector(
                          
onTap: () {
  setState(() {
    if (selectedSort == index) {
      selectedSort = -1;
      filteredLawyers = List.from(lawyers);
    } else {
      selectedSort = index;
      _applySorting();
    }
  });
},


                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color.fromARGB(255, 6, 61, 65)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Text(
                                sortOptions[index],
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          //  عرض النتائج
          Expanded(
            child: filteredLawyers.isEmpty
                ? const Center(
                    child: Text('لا يوجد محامي مطابق للبحث',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredLawyers.length,
                    itemBuilder: (context, index) {
                      final lawyer = filteredLawyers[index];
                      return _buildLawyerCard(lawyer);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentRoute: '/search'),
      floatingActionButton: _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildLawyerCard(Map<String, dynamic> lawyer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 28, backgroundImage: NetworkImage(lawyer['image'])),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lawyer['name'],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(lawyer['rating'].toString(),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoChip(lawyer['experience']),
              _infoChip(lawyer['speciality']),
              _infoChip(lawyer['subSpeciality']),
              _infoChip(lawyer['ssubSpeciality']),
              _infoChip(lawyer['academic']),
              _infoChip(lawyer['degree']),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.grey, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${lawyer['price']} ر.س',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 6, 61, 65))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 6, 61, 65),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('حجز موعد',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
        child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87)),
      );

  Widget _buildFab(BuildContext context) => Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
              colors: [Color.fromARGB(255, 6, 61, 65), Color.fromARGB(255, 8, 65, 69)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          boxShadow: const [
            BoxShadow(color: Color.fromARGB(255, 31, 79, 83), blurRadius: 10, offset: Offset(0, 4))
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/plus'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      );


  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          Widget buildChips(List<String> options, List<String> selected) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((item) {
                final isSelected = selected.contains(item);
                return GestureDetector(
                  onTap: () {
                    setModalState(() {
                      isSelected ? selected.remove(item) : selected.add(item);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color.fromARGB(255, 6, 61, 65)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(item,
                        style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade800,
                            fontWeight: FontWeight.w500)),
                  ),
                );
              }).toList(),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Center(child: Icon(Icons.drag_handle, color: Colors.grey, size: 30)),
                const SizedBox(height: 10),
                const Text('التخصص الأكاديمي',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                buildChips(academicOptions, selectedAcademic),
                const SizedBox(height: 16),
                const Text('الدرجة العلمية',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                buildChips(degreeOptions, selectedDegree),
                const SizedBox(height: 16),
                const Text('التخصص',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                buildChips(specialityOptions, selectedSpeciality),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: () {
                          setModalState(() {
                            selectedAcademic.clear();
                            selectedDegree.clear();
                            selectedSpeciality.clear();
                          });
                        },
                        child: const Text('إزالة ',
                            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 6, 61, 65),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: _applyFilters,
                        child: const Text('تطبيق',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                )
              ]),
            ),
          );
        });
      },
    );
  }
}
