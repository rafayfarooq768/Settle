import 'package:flutter_test/flutter_test.dart';
import 'package:settle/core/money/money.dart';

void main() {
  // A owes B Rs 300, everyone else is even.
  const nets = {'a': -30000, 'b': 30000, 'c': 0};

  test('the payment that clears the last debt settles everyone', () {
    expect(settlesEveryone(nets, from: 'a', to: 'b', amount: 30000), isTrue);
  });

  test('a part payment does not', () {
    expect(settlesEveryone(nets, from: 'a', to: 'b', amount: 10000), isFalse);
  });

  test('paying more than owed does not', () {
    expect(settlesEveryone(nets, from: 'a', to: 'b', amount: 40000), isFalse);
  });

  test('others still owing means not settled', () {
    const more = {'a': -30000, 'b': 50000, 'c': -20000};
    expect(settlesEveryone(more, from: 'a', to: 'b', amount: 30000), isFalse);
  });

  test('unknown members never count as settled', () {
    expect(settlesEveryone(nets, from: 'x', to: 'b', amount: 30000), isFalse);
  });
}
