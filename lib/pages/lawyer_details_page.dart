import 'package:flutter/material.dart';
import '../widgets/app_bottom_nav.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'case_details_page.dart';

class LawyerDetailsPage extends StatefulWidget {
  final int lawyerId;

  const LawyerDetailsPage({super.key, required this.lawyerId});

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
        'http://10.71.214.246:8888/mujeer_api/get_lawyer_details.php?id=${widget.lawyerId}');
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
        'http://10.71.214.246:8888/mujeer_api/get_lawyer_ratings.php?id=${widget.lawyerId}');
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
        'http://10.71.214.246:8888/mujeer_api/get_lawyer_comments.php?id=${widget.lawyerId}');
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      floatingActionButton: _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const AppBottomNav(currentRoute: '/search'),
      
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: const Color.fromARGB(255, 6, 61, 65),
                strokeWidth: screenWidth * 0.008,
              ),
            )
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.04,
                    screenHeight * 0.08,
                    screenWidth * 0.04,
                    kBottomNavigationBarHeight + bottomPadding + screenHeight * 0.12, // زدنا المساحة
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(screenWidth * 0.045), // خففنا قليلاً
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(screenWidth * 0.05),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: screenWidth * 0.11,
                          backgroundImage: NetworkImage(lawyer!['image']),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: screenWidth * 0.055,
                            ),
                            SizedBox(width: screenWidth * 0.01),
                            Text(
                              lawyer!['rating'].toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.04,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.005,
                            horizontal: screenWidth * 0.035,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(screenWidth * 0.025),
                          ),
                          child: Text(
                            'رقم الرخصة: ${lawyer!['license']}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: screenWidth * 0.03,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.012),
                        Text(
                          lawyer!['name'],
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 6, 61, 65),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.028), // خففنا من 0.03
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _roundedBox(
                              Icons.work_outline,
                              'الخبرة',
                              lawyer!['experience'],
                              screenWidth,
                              screenHeight,
                            ),
                            _roundedBox(
                              Icons.school_outlined,
                              'التخصص الأكاديمي',
                              lawyer!['academic'],
                              screenWidth,
                              screenHeight,
                            ),
                            _roundedBox(
                              Icons.workspace_premium_outlined,
                              'الدرجة العلمية',
                              lawyer!['degree'],
                              screenWidth,
                              screenHeight,
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.045), // خففنا من 0.05
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'التخصصات القانونية:',
                            style: TextStyle(
                              color: const Color.fromARGB(255, 6, 61, 65),
                              fontSize: screenWidth * 0.038,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Wrap(
                          spacing: screenWidth * 0.015,
                          runSpacing: screenHeight * 0.01,
                          children: [
                            _smallTag(lawyer!['speciality'], screenWidth),
                            _smallTag(lawyer!['subSpeciality'], screenWidth),
                            _smallTag(lawyer!['ssubSpeciality'], screenWidth),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.028), // خففنا من 0.03

                        // تقييمات
                        loadingRatings
                            ? CircularProgressIndicator(
                                color: const Color.fromARGB(255, 6, 61, 65),
                                strokeWidth: screenWidth * 0.008,
                              )
                            : (ratings == null
                                ? Text(
                                    "لا يوجد تقييمات",
                                    style: TextStyle(fontSize: screenWidth * 0.04),
                                  )
                                : _buildRatingsSection(screenWidth, screenHeight)),

                        SizedBox(height: screenHeight * 0.035), // خففنا من 0.04

                        _buildCommentsSection(screenWidth, screenHeight),
                        
                        // مساحة إضافية قبل الزر
                        SizedBox(height: screenHeight * 0.035),
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CaseDetailsPage(
                                    lawyerId: widget.lawyerId,
                                    price: (lawyer!['price'] as num).toDouble(),
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 6, 61, 65),
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.018, // خففنا
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(screenWidth * 0.075),
                              ),
                            ),
                            child: Text(
                              'حجز موعد',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        
                        // مساحة إضافية في النهاية لمنع الـ overflow
                        SizedBox(height: kBottomNavigationBarHeight * 0.6),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  top: screenHeight * 0.05,
                  right: screenWidth * 0.04,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.grey,
                      size: screenWidth * 0.06,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFab(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      width: screenWidth * 0.16,
      height: screenWidth * 0.16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 6, 61, 65),
            Color.fromARGB(255, 8, 65, 69)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(255, 31, 79, 83),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => Navigator.pushReplacementNamed(context, '/plus'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: screenWidth * 0.07,
        ),
      ),
    );
  }

  Widget _roundedBox(
  IconData icon,
  String title,
  String value,
  double screenWidth,
  double screenHeight,
) {
  return Container(
    width: screenWidth * 0.24,
    padding: EdgeInsets.all(screenWidth * 0.02),
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(screenWidth * 0.045),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min, // ⭐ مهم
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: Colors.grey[700],
          size: screenWidth * 0.05,
        ),
        SizedBox(height: screenHeight * 0.005),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: screenWidth * 0.028,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: screenHeight * 0.003),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 2, // ⭐ حماية إضافية
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: screenWidth * 0.028,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}


  Widget _smallTag(String text, double screenWidth) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.022, // خففنا
        vertical: screenWidth * 0.013, // خففنا
      ),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(screenWidth * 0.045), // خففنا
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.black87,
          fontSize: screenWidth * 0.03, // خففنا
        ),
      ),
    );
  }

  Widget _buildRatingsSection(double screenWidth, double screenHeight) {
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
              color: const Color.fromARGB(255, 6, 61, 65),
              fontSize: screenWidth * 0.038,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: screenHeight * 0.012), // خففنا
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$avg / 5",
                style: TextStyle(
                  fontSize: screenWidth * 0.055, // خففنا
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
              SizedBox(height: screenHeight * 0.003), // خففنا
              Text(
                "$count من التقييمات",
                style: TextStyle(
                  fontSize: screenWidth * 0.032, // خففنا
                  color: Colors.grey,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
        SizedBox(height: screenHeight * 0.012), // خففنا
        Column(
          children: List.generate(5, (i) {
            int star = 5 - i;
            double p = percent(star);

            return Padding(
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.004), // خففنا
              child: Row(
                children: [
                  Text(
                    "${p.toStringAsFixed(2)}%",
                    style: TextStyle(fontSize: screenWidth * 0.03), // خففنا
                  ),
                  SizedBox(width: screenWidth * 0.012), // خففنا
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: screenHeight * 0.007, // خففنا
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(screenWidth * 0.045),
                          ),
                        ),
                        Container(
                          height: screenHeight * 0.007, // خففنا
                          width: (p * 2),
                          decoration: BoxDecoration(
                            color: star == 5
                                ? const Color.fromARGB(255, 6, 61, 65)
                                : Colors.grey[400],
                            borderRadius: BorderRadius.circular(screenWidth * 0.045),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.012), // خففنا
                  Row(
                    children: List.generate(
                      star,
                      (x) => Icon(
                        Icons.star,
                        size: screenWidth * 0.04, // خففنا
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

  Widget _buildCommentsSection(double screenWidth, double screenHeight) {
    if (loadingComments) {
      return Center(
        child: CircularProgressIndicator(
          color: const Color.fromARGB(255, 6, 61, 65),
          strokeWidth: screenWidth * 0.008,
        ),
      );
    }

    if (comments.isEmpty) {
      return Text(
        "لا توجد تعليقات",
        style: TextStyle(fontSize: screenWidth * 0.04),
      );
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
              color: const Color.fromARGB(255, 6, 61, 65),
              fontSize: screenWidth * 0.038,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: screenHeight * 0.018), // خففنا
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
                        (x) => Icon(
                          Icons.star,
                          size: screenWidth * 0.042, // خففنا
                          color: Colors.amber,
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.018), // خففنا
                    Expanded(
                      child: Text(
                        c["username"],
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.035, // خففنا
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.005), // خففنا
                Text(
                  c["review"],
                  style: TextStyle(fontSize: screenWidth * 0.033), // خففنا
                ),
                Divider(height: screenHeight * 0.022), // خففنا
              ],
            );
          }).toList(),
        ),
        if (comments.length > 3)
          Center(
            child: TextButton(
              onPressed: _showAllComments,
              child: Text(
                "المزيد",
                style: TextStyle(
                  color: const Color.fromARGB(255, 6, 61, 65),
                  fontSize: screenWidth * 0.038,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showAllComments() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(screenWidth * 0.05),
        ),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: comments.map((c) {
                return Padding(
                  padding: EdgeInsets.only(bottom: screenHeight * 0.018), // خففنا
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        textDirection: TextDirection.ltr,
                        children: [
                          Row(
                            children: List.generate(
                              c["rate"],
                              (x) => Icon(
                                Icons.star,
                                size: screenWidth * 0.042, // خففنا
                                color: Colors.amber,
                              ),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.018), // خففنا
                          Expanded(
                            child: Text(
                              c["username"],
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.035, // خففنا
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.005), // خففنا
                      Text(
                        c["review"],
                        style: TextStyle(fontSize: screenWidth * 0.033), // خففنا
                      ),
                      Divider(),
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