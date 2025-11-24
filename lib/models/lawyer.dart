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
  final idVal    = j['LawyerID'] ?? j['lawyer_id'] ?? j['id'];
  final nameVal  = j['FullName'] ?? j['full_name'] ?? j['name'] ?? '';
  final rawPhoto = (j['LawyerPhoto'] ?? j['photo'] ?? j['image'] ?? '').toString().trim();
  final ratingVal= j['Rating'] ?? j['rating'] ?? 0;

  
  const baseUrl = 'http://10.0.2.2:8888/mujeer_api';
  //  const baseUrl = 'http://192.168.3.10:8888/mujeer_api';
  
  final photoUrl = rawPhoto.isEmpty
      ? ''
      : (rawPhoto.startsWith('http') ? rawPhoto : '$baseUrl/uploads/$rawPhoto');

  return Lawyer(
    id: int.tryParse('$idVal') ?? 0,
    fullName: nameVal.toString(),
    photoUrl: photoUrl,
    rating: double.tryParse('$ratingVal') ?? 0.0,
  );
}

}
