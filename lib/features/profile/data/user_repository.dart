import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_fields.dart';
import '../domain/app_user.dart';
import '../domain/payment_method.dart';

/// `users/{uid}`: private to its owner (PLAN.md §7).
class UserRepository {
  UserRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Json> _user(String uid) =>
      _db.collection(Col.users).doc(uid);

  Stream<AppUser?> watch(String uid) =>
      _user(uid)
          .snapshots()
          .map((d) => d.exists ? appUserFromMap(d.id, d.data()!) : null);

  /// Creates the profile on first sign-in, and fills in the name (and the
  /// phone typed at sign-up) if they were empty: email sign-up sets the name
  /// a moment after creating the account.
  Future<void> ensureUser({
    required String uid,
    required String displayName,
    required String email,
    String phone = '',
  }) async {
    final ref = _user(uid);
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        'displayName': displayName,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'paymentMethods': <Json>[],
        'phone': phone,
      });
      return;
    }
    final data = doc.data()!;
    final update = <String, Object?>{
      if (readString(data['displayName']).isEmpty && displayName.isNotEmpty)
        'displayName': displayName,
      if (readString(data['phone']).isEmpty && phone.isNotEmpty) 'phone': phone,
    };
    if (update.isNotEmpty) await ref.update(update);
  }
}

AppUser appUserFromMap(String uid, Json data) => AppUser(
  uid: uid,
  displayName: readString(data['displayName']),
  email: readString(data['email']),
  createdAt: readDate(data['createdAt']),
  paymentMethods: PaymentMethod.listFrom(data['paymentMethods']),
  phone: readString(data['phone']),
);
