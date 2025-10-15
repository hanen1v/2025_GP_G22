class Lawyer {
  final int id;
  final String fullName;
  final String photoUrl;
  final double rating;

  Lawyer({
    required this.id,
    required this.fullName,
    required this.photoUrl,
    required this.rating,
  });

  factory Lawyer.fromJson(Map<String, dynamic> j) {
    // نحاول نقرأ Points من الـ JSON
    final ratingValue = double.tryParse('${j['Points'] ?? j['Rating'] ?? 0}') ?? 0.0;
    final rating = double.parse(ratingValue.clamp(0, 5).toStringAsFixed(1));

    // نكوّن الرابط الكامل للصورة
    final photoName = (j['LawyerPhoto'] ?? '').toString().trim();
    const baseUrl = 'http://10.0.2.2:8888/mujeer_api'; // غيّريه لو غيرتي اسم مجلد الـ backend
    final fullPhotoUrl = photoName.isEmpty ? '' : '$baseUrl/uploads/$photoName';

    return Lawyer(
      id: int.tryParse('${j['LawyerID']}') ?? 0,
      fullName: (j['FullName'] ?? '').toString(),
      photoUrl: fullPhotoUrl,
      rating: rating,
    );
  }
}
