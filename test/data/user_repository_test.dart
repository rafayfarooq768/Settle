import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/features/profile/data/user_repository.dart';

/// The private profile, `users/{uid}` (PLAN.md §7).
void main() {
  late FakeFirebaseFirestore db;
  late UserRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = UserRepository(db);
  });

  test('first sign-in creates the profile', () async {
    await repo.ensureUser(
      uid: 'u1',
      displayName: 'Ali',
      email: 'ali@example.com',
      phone: '+923001234567',
    );
    final user = (await repo.watch('u1').first)!;
    expect(user.displayName, 'Ali');
    expect(user.email, 'ali@example.com');
    expect(user.phone, '+923001234567');
    expect(user.paymentMethods, isEmpty);
  });

  test('signing in again keeps what was saved', () async {
    await repo.ensureUser(uid: 'u1', displayName: 'Ali', email: 'a@x.com');
    await db.doc('users/u1').update({
      'displayName': 'Ali Khan',
      'phone': '+923001234567',
      'paymentMethods': [
        {
          'id': 'p1',
          'name': 'Nayapay',
          'accountTitle': 'Ali',
          'accountNumber': '0300',
        },
      ],
    });
    await repo.ensureUser(
      uid: 'u1',
      displayName: 'Google Name',
      email: 'a@x.com',
      phone: '+920000000000',
    );
    final user = (await repo.watch('u1').first)!;
    expect(user.displayName, 'Ali Khan');
    expect(user.phone, '+923001234567');
    expect(user.paymentMethods.single.name, 'Nayapay');
  });

  // Email sign-up sets the name a moment after creating the account, so
  // the profile may first be made with an empty name.
  test('an empty name or phone is filled in later', () async {
    await repo.ensureUser(uid: 'u1', displayName: '', email: 'a@x.com');
    await repo.ensureUser(
      uid: 'u1',
      displayName: 'Sara',
      email: 'a@x.com',
      phone: '+923331112222',
    );
    final user = (await repo.watch('u1').first)!;
    expect(user.displayName, 'Sara');
    expect(user.phone, '+923331112222');
  });

  test('someone with no profile reads as null', () async {
    expect(await repo.watch('nobody').first, isNull);
  });
}
