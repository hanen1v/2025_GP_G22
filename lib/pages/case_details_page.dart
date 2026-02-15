import 'package:flutter/material.dart';
import '../widgets/app_bottom_nav.dart';
import 'package:iconsax/iconsax.dart';
import 'package:file_picker/file_picker.dart';
import 'select_time_page.dart';
import 'payment_page.dart';
import '../models/request_type.dart'; 

class CaseDetailsPage extends StatefulWidget {
  final int lawyerId;
  final double price;
  final int timeslotId;
  final RequestType requestType; 

  const CaseDetailsPage({
    super.key,
    required this.lawyerId,
    required this.price,
    required this.timeslotId,
    required this.requestType, 
  });

  @override
  State<CaseDetailsPage> createState() => _CaseDetailsPageState();
}

class _CaseDetailsPageState extends State<CaseDetailsPage> {
  final TextEditingController _detailsController = TextEditingController();
  bool _detailsError = false;
  String? _attachedFile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      floatingActionButton: _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar:
          const AppBottomNav(currentRoute: '/case_details'),

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
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.requestType == RequestType.contractReview
                            ? 'أدخل ملاحظاتك (اختياري):'
                            : 'أدخل تفاصيل الطلب:',
                        style: const TextStyle(
                          color: Color.fromARGB(255, 6, 61, 65),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: _detailsController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[200],
                          hintText: 'اكتب تفاصيل الطلب هنا...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          errorText: _detailsError
                              ? 'يجب إدخال تفاصيل الطلب'
                              : null,
                        ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Icon(Iconsax.attach_circle,
                              color: Colors.grey[700]),
                          const SizedBox(width: 8),

                          
                          Text(
                            widget.requestType == RequestType.contractReview
                                ? 'إرفاق ملف (إجباري)'
                                : 'إرفاق ملف (اختياري)',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w500),
                          ),

                          const Spacer(),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            onPressed: () async {
                              final result =
                                  await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: [
                                  'pdf',
                                  'jpg',
                                  'png',
                                  'doc',
                                  'docx'
                                ],
                              );

                              if (result != null &&
                                  result.files.isNotEmpty) {
                                setState(() {
                                  _attachedFile =
                                      result.files.single.name;
                                });
                              }
                            },
                            child: const Text(
                              'اختيار ملف',
                              style: TextStyle(color: Colors.black87),
                            ),
                          ),
                        ],
                      ),

                      if (_attachedFile != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _attachedFile!,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 14),
                        ),
                      ],

                      const SizedBox(height: 60),

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
                          onPressed: () {
                            if (widget.requestType ==
                                    RequestType.consultation &&
                                _detailsController.text
                                    .trim()
                                    .isEmpty) {
                              setState(() => _detailsError = true);
                              return;
                            }

                            if (widget.requestType ==
                                    RequestType.contractReview &&
                                _attachedFile == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'يجب إرفاق ملف لمراجعة العقد'),
                                ),
                              );
                              return;
                            }

                            setState(() => _detailsError = false);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentPage(
                                  lawyerId: widget.lawyerId,
                                  timeslotId: widget.timeslotId,
                                  price: widget.price,
                                  caseDetails:
                                      _detailsController.text,
                                  attachedFileName: _attachedFile,
                                   requestType: widget.requestType,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'الانتقال إلى الدفع',
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
    );
  }

  Widget _buildFab(BuildContext context) => Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 6, 61, 65),
              Color.fromARGB(255, 8, 65, 69),
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
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      );
}
