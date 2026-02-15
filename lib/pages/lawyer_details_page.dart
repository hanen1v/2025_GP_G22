import 'package:flutter/material.dart';
import '../widgets/app_bottom_nav.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'case_details_page.dart';
import 'select_time_page.dart';
import '../models/request_type.dart';

class LawyerDetailsPage extends StatefulWidget {
  final int lawyerId;
  final RequestType requestType; 

  const LawyerDetailsPage({
    super.key,
    required this.lawyerId,
    required this.requestType, 
  });


  @override
  State<LawyerDetailsPage> createState() => _LawyerDetailsPageState();
}

class _LawyerDetailsPageState extends State<LawyerDetailsPage> {
  Map<String, dynamic>? lawyer;
  bool isLoading = true;

  Map<String, dynamic>? ratings;
  bool loadingRatings = true;

  List<dynamic> comments = [];
  bool loadingComments = true;

  Future<void> _fetchLawyerDetails() async {
    final url = Uri.parse(
        'http://10.0.2.2:8888/mujeer_api/get_lawyer_details.php?id=${widget.lawyerId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          lawyer = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchRatings() async {
    final url = Uri.parse(
        'http://10.0.2.2:8888/mujeer_api/get_lawyer_ratings.php?id=${widget.lawyerId}');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          ratings = jsonDecode(response.body);
          loadingRatings = false;
        });
      } else {
        setState(() => loadingRatings = false);
      }
    } catch (e) {
      setState(() => loadingRatings = false);
    }
  }

  Future<void> _fetchComments() async {
    final url = Uri.parse(
        'http://10.0.2.2:8888/mujeer_api/get_lawyer_comments.php?id=${widget.lawyerId}');
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        setState(() {
          comments = jsonDecode(res.body);
          loadingComments = false;
        });
      } else {
        setState(() => loadingComments = false);
      }
    } catch (e) {
      setState(() => loadingComments = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchLawyerDetails();
    _fetchRatings();
    _fetchComments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      floatingActionButton: _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: const AppBottomNav(currentRoute: '/search'),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color.fromARGB(255, 6, 61, 65)))
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 100, 16, 50),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundImage: NetworkImage(lawyer!['image']),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                           Icon(
      Icons.star,
      size: 22,
      color: (lawyer!['rating'] == null ||
              lawyer!['rating'] == 0)
          ? Colors.grey  
          : Colors.amber,
    ),
                            const SizedBox(width: 4),
                            Text(
                              lawyer!['rating'].toString(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'رقم الرخصة: ${lawyer!['license']}',
                            style:
                                TextStyle(color: Colors.grey[700], fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          lawyer!['name'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 6, 61, 65),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _roundedBox(Icons.work_outline, 'الخبرة',
                                lawyer!['experience']),
                            _roundedBox(Icons.school_outlined,
                                'التخصص الأكاديمي', lawyer!['academic']),
                            _roundedBox(Icons.workspace_premium_outlined,
                                'الدرجة العلمية', lawyer!['degree']),
                          ],
                        ),
                        const SizedBox(height: 50),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'التخصصات القانونية:',
                            style: TextStyle(
                              color: Color.fromARGB(255, 6, 61, 65),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _smallTag(lawyer!['speciality']),
                            _smallTag(lawyer!['subSpeciality']),
                            _smallTag(lawyer!['ssubSpeciality']),
                          ],
                        ),
                        const SizedBox(height: 30),

                        loadingRatings
                            ? const CircularProgressIndicator(
                                color: Color.fromARGB(255, 6, 61, 65))
                            : (ratings == null
                                ? const Text("لا يوجد تقييمات")
                                : _buildRatingsSection()),

                        const SizedBox(height: 40),

                        _buildCommentsSection(),
                        const SizedBox(height: 40),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SelectTimePage(
  lawyerId: widget.lawyerId,
  price: (lawyer!['price'] as num).toDouble(),
  requestType: widget.requestType, 
),


                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 6, 61, 65),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'حجز موعد',
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

                Positioned(
                  top: 45,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
    );
  }

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
            BoxShadow(
                color: Color.fromARGB(255, 31, 79, 83),
                blurRadius: 10,
                offset: Offset(0, 4))
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/plus'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      );



  Widget _roundedBox(IconData icon, String title, String value) {
    return Container(
      width: 100,
      height: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey[700], size: 22),
          const SizedBox(height: 6),
          Text(title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _smallTag(String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black87, fontSize: 13),
      ),
    );
  }

  Widget _buildRatingsSection() {
    final avg = ratings!['average'];
    final count = ratings!['count'];
    final stars = ratings!['stars'];

    double percent(int s) {
      if (count == 0) return 0;
      return (stars[s.toString()] / count) * 100;
    }

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            "التقييمات:",
            style: TextStyle(
              color: Color.fromARGB(255, 6, 61, 65),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 15),
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$avg / 5",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 4),
              Text(
                "$count من التقييمات",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Column(
          children: List.generate(5, (i) {
            int star = 5 - i;
            double p = percent(star);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text("${p.toStringAsFixed(2)}%"),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        Container(
                          height: 8,
                          width: (p * 2),
                          decoration: BoxDecoration(
                            color: star == 5
                                ? const Color.fromARGB(255, 6, 61, 65)
                                : Colors.grey[400],
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    children: List.generate(
                      star,
                      (x) => const Icon(
                        Icons.star,
                        size: 18,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    if (loadingComments) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color.fromARGB(255, 6, 61, 65),
        ),
      );
    }

    if (comments.isEmpty) {
      return const Text("لا توجد تعليقات");
    }

    final firstThree = comments.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            "آراء العملاء:",
            style: TextStyle(
              color: Color.fromARGB(255, 6, 61, 65),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Column(
          children: firstThree.map((c) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    Row(
                      children: List.generate(
                        c["rate"],
                        (x) =>
                            const Icon(Icons.star, size: 18, color: Colors.amber),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c["username"],
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  c["review"],
                  style: const TextStyle(fontSize: 14),
                ),
                const Divider(height: 25),
              ],
            );
          }).toList(),
        ),
        if (comments.length > 3)
          Center(
            child: TextButton(
              onPressed: _showAllComments,
              child: const Text(
                "المزيد",
                style: TextStyle(
                    color: Color.fromARGB(255, 6, 61, 65),
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  void _showAllComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: comments.map((c) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        textDirection: TextDirection.ltr,
                        children: [
                          Row(
                            children: List.generate(
                              c["rate"],
                              (x) => const Icon(Icons.star,
                                  size: 18, color: Colors.amber),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c["username"],
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        c["review"],
                        style: const TextStyle(fontSize: 14),
                      ),
                      const Divider(),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
