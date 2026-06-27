import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SkillLevel { beginner, intermediate, advanced, pro }

extension SkillLevelX on SkillLevel {
  String get label {
    switch (this) {
      case SkillLevel.beginner:
        return 'Beginner';
      case SkillLevel.intermediate:
        return 'Intermediate';
      case SkillLevel.advanced:
        return 'Advanced';
      case SkillLevel.pro:
        return 'Pro';
    }
  }

  static SkillLevel parse(String? raw) => SkillLevel.values
      .firstWhere((s) => s.name == raw, orElse: () => SkillLevel.intermediate);
}

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.phone,
    required this.preferredSport,
    required this.skillLevel,
    required this.favoriteSport,
    required this.memberSince,
  });

  final String uid;
  final String displayName;
  final String email;
  final String phone;
  final String preferredSport;
  final SkillLevel skillLevel;
  final String favoriteSport;
  final DateTime memberSince;

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? phone,
    String? preferredSport,
    SkillLevel? skillLevel,
    String? favoriteSport,
  }) =>
      UserProfile(
        uid: uid,
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        preferredSport: preferredSport ?? this.preferredSport,
        skillLevel: skillLevel ?? this.skillLevel,
        favoriteSport: favoriteSport ?? this.favoriteSport,
        memberSince: memberSince,
      );

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'email': email,
        'phone': phone,
        'preferredSport': preferredSport,
        'skillLevel': skillLevel.name,
        'favoriteSport': favoriteSport,
        'memberSince': Timestamp.fromDate(memberSince),
      };

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return UserProfile(
      uid: doc.id,
      displayName: d['displayName'] as String? ?? '',
      email: d['email'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      preferredSport: d['preferredSport'] as String? ?? 'Badminton',
      skillLevel: SkillLevelX.parse(d['skillLevel'] as String?),
      favoriteSport: d['favoriteSport'] as String? ?? 'Badminton',
      memberSince:
          (d['memberSince'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory UserProfile.empty(String uid) => UserProfile(
        uid: uid,
        displayName: '',
        email: '',
        phone: '',
        preferredSport: 'Badminton',
        skillLevel: SkillLevel.intermediate,
        favoriteSport: 'Badminton',
        memberSince: DateTime.now(),
      );
}

class UserProfileRepository {
  UserProfileRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('users');

  Stream<UserProfile?> stream(String uid) {
    return _col.doc(uid).snapshots().map((s) {
      if (!s.exists) return UserProfile.empty(uid);
      return UserProfile.fromDoc(s);
    });
  }

  Future<void> save(UserProfile profile) async {
    await _col.doc(profile.uid).set(profile.toMap(), SetOptions(merge: true));
  }

  /// Merge only the given fields, leaving everything else (sport, skill, …)
  /// untouched. Used when linking an account so we don't clobber a profile the
  /// user may have already filled in.
  Future<void> merge(
    String uid, {
    String? displayName,
    String? email,
    String? phone,
  }) async {
    final data = <String, dynamic>{
      if (displayName != null && displayName.isNotEmpty)
        'displayName': displayName,
      if (email != null && email.isNotEmpty) 'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    };
    if (data.isEmpty) return;
    await _col.doc(uid).set(data, SetOptions(merge: true));
  }

  /// Delete the profile doc — used when the user deletes their account.
  Future<void> delete(String uid) async {
    await _col.doc(uid).delete();
  }
}

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository(FirebaseFirestore.instance);
});
