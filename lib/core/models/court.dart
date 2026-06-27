enum CourtType {
  badminton,
  pickleball,
  basketball,
}

extension CourtTypeDisplay on CourtType {
  String get label {
    switch (this) {
      case CourtType.badminton:
        return 'BADMINTON';
      case CourtType.pickleball:
        return 'PICKLEBALL';
      case CourtType.basketball:
        return 'BASKETBALL';
    }
  }

  String get shortLabel {
    switch (this) {
      case CourtType.badminton:
        return 'Badminton';
      case CourtType.pickleball:
        return 'Pickleball';
      case CourtType.basketball:
        return 'Basketball';
    }
  }
}

class Court {
  const Court({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.price,
    required this.rating,
    required this.numberOfCourts,
    required this.amenities,
    required this.image,
    this.images = const [],
    this.description = '',
    this.phone,
    this.email,
    this.mapUrl,
    this.latitude,
    this.longitude,
    this.ownerId,
    this.published = true,
  });

  final String id;
  final String name;
  final CourtType type;
  final String location;
  final double price;
  final double rating;
  final int numberOfCourts;
  final List<String> amenities;
  final String image;
  final List<String> images;
  final String description;
  final String? phone;
  final String? email;
  final String? mapUrl;
  final double? latitude;
  final double? longitude;
  final String? ownerId;
  final bool published;

  factory Court.fromFirestore(String id, Map<String, dynamic> data) {
    return Court(
      id: id,
      name: (data['name'] as String?) ?? '',
      type: _typeFromString(data['type'] as String?),
      location: (data['location'] as String?) ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      numberOfCourts: (data['numberOfCourts'] as num?)?.toInt() ?? 1,
      amenities: ((data['amenities'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      image: (data['image'] as String?) ?? '',
      images: _imagesFrom(data),
      description: (data['description'] as String?) ?? '',
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      mapUrl: data['mapUrl'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      ownerId: data['ownerId'] as String?,
      published: (data['published'] as bool?) ?? false,
    );
  }
}

/// Gallery images. Prefers the `images` array; falls back to the single
/// `image` (cover) so courts created before multi-image still show a photo.
List<String> _imagesFrom(Map<String, dynamic> data) {
  final raw = data['images'];
  if (raw is List && raw.isNotEmpty) {
    return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }
  final cover = (data['image'] as String?) ?? '';
  return cover.isNotEmpty ? [cover] : const [];
}

CourtType _typeFromString(String? s) {
  switch (s) {
    case 'pickleball':
      return CourtType.pickleball;
    case 'basketball':
      return CourtType.basketball;
    case 'badminton':
    default:
      return CourtType.badminton;
  }
}
