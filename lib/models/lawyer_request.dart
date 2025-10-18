class LawyerRequest {
  final int id;
  final String lawyerName;
  final String licenseNumber;
  final String LicenseFile; 
  final String status;

  const LawyerRequest({
    required this.id,
    required this.lawyerName,
    required this.licenseNumber,
    required this.LicenseFile,
    required this.status,
  });

  factory LawyerRequest.fromJson(Map<String, dynamic> j) {
        final fileName = (j['LawyerLicense'] ?? '').toString().trim();
        const baseUrl = 'http://10.0.2.2/mujeer_api'; // غيّريه لو تغيّر المسار
        final fullFileUrl = fileName.isEmpty ? '' : '$baseUrl/uploads/$fileName';
    return LawyerRequest(
      id: int.parse(j['RequestID'].toString()),
      lawyerName: (j['LawyerName'] ?? '').toString(),
      licenseNumber: (j['LicenseNumber'] ?? '').toString(),
      LicenseFile:fullFileUrl,
      status: (j['Status'] ?? 'Pending').toString(),
    );
  }
}
