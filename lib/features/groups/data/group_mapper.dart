import '../../../core/firestore/firestore_fields.dart';
import '../../profile/domain/payment_method.dart';
import '../domain/group.dart';

Group groupFromMap(String id, Json data) => Group(
  id: id,
  name: readString(data['name']),
  type: readString(data['type']),
  createdBy: readString(data['createdBy']),
  createdAt: readDate(data['createdAt']),
  joinCode: readString(data['joinCode']),
  memberUids: readStringList(data['memberUids']),
  currency: data['currency'] as String? ?? 'PKR',
);

Member memberFromMap(String id, Json data) => Member(
  id: id,
  displayName: readString(data['displayName']),
  uid: data['uid'] as String?,
  claimedAt: readOptionalDate(data['claimedAt']),
  joinedAt: readDate(data['joinedAt']),
  active: readBool(data['active'], fallback: true),
  paymentMethods: PaymentMethod.listFrom(data['paymentMethods']),
  phone: readString(data['phone']),
);

List<Json> paymentMethodsToList(List<PaymentMethod> methods) => [
  for (final m in methods) m.toMap(),
];
