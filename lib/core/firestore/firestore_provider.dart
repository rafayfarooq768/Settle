import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The one Firestore instance. Offline persistence is on by default on
/// Android, which gives PLAN.md §3 offline use. Only repositories read this.
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);
