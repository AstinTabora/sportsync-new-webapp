class CourtModel {
  const CourtModel({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.rating,
    required this.location,
    required this.phone,
    required this.numberOfCourts,
    required this.amenities,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final String type;
  final double price;
  final double rating;
  final String location;
  final String phone;
  final int numberOfCourts;
  final List<String> amenities;
  final double latitude;
  final double longitude;

  factory CourtModel.fromMap(Map<String, dynamic> map) {
    final coordinates = (map['coordinates'] as Map?) ?? const {};

    return CourtModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      location: map['location']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      numberOfCourts: (map['numberOfCourts'] as num?)?.toInt() ?? 0,
      amenities: (map['amenities'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      latitude: (coordinates['lat'] as num?)?.toDouble() ?? 0,
      longitude: (coordinates['lng'] as num?)?.toDouble() ?? 0,
    );
  }
}
