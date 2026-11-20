import '../../groups/domain/group.dart';

/// Members for the Balances tab (DESIGN.md §11): largest owed first,
/// largest owes last. Removed placeholders still show while they have a
/// balance. Ties keep the group's member order.
List<Member> balanceRows(List<Member> members, Map<String, int> nets) {
  int net(Member m) => nets[m.id] ?? 0;
  final shown = [
    for (final m in members)
      if (m.active || net(m) != 0) m,
  ];
  final position = {for (var i = 0; i < shown.length; i++) shown[i].id: i};
  return shown..sort((a, b) {
    final byNet = net(b).compareTo(net(a));
    return byNet != 0 ? byNet : position[a.id]!.compareTo(position[b.id]!);
  });
}
