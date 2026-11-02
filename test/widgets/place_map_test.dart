import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bridgeit/content/models.dart';
import 'package:bridgeit/theme/app_theme.dart';
import 'package:bridgeit/widgets/place_map.dart';

Place _place(String id, String name) =>
    Place(id: id, name: name, pinX: 0, pinY: 0, pictures: const []);

// Content order, as in levels.json.
final _places = [
  _place('la_paz', 'Laoag La Paz Sand Dunes'),
  _place('burgos', 'Burgos Lighthouse (Cape Bojeador)'),
  _place('bangui', 'Bangui Windmills'),
  _place('paoay', 'San Agustin Church of Paoay'),
  _place('saud', 'Saud Beach, Pagudpud'),
  _place('badoc', 'La Virgen Milagrosa de Badoc Church'),
  _place('pangil', 'Pangil Coral Rock Formations, Currimao'),
];

Future<List<Place>> _pump(WidgetTester tester, {Size? size}) async {
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
  final chosen = <Place>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: PlaceMap(places: _places, onChosen: chosen.add),
      ),
    ),
  );
  return chosen;
}

FilledButton _drive(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byType(FilledButton));

void main() {
  test('places run north to south; unknown ids come last', () {
    final order = mapOrder([..._places, _place('vigan', 'Vigan')]);
    expect(order.first.id, 'saud');
    expect(order[6].id, 'badoc');
    expect(order.last.id, 'vigan');
    expect(order.map((p) => p.id).take(7), northToSouth);
  });

  testWidgets('Drive waits for a place, then drives there', (tester) async {
    final chosen = await _pump(tester);
    expect(find.text('Choose a place'), findsOneWidget);
    expect(_drive(tester).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('pin-burgos')));
    await tester.pump();
    expect(
      find.text('Drive to Burgos Lighthouse (Cape Bojeador)'),
      findsOneWidget,
    );
    expect(chosen, isEmpty);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(chosen.single.id, 'burgos');
  });

  testWidgets('every place is reachable on a 360x640 phone', (tester) async {
    await _pump(tester, size: const Size(360, 640));
    expect(tester.takeException(), isNull);
    for (final place in _places) {
      final pin = find.byKey(ValueKey('pin-${place.id}'));
      await tester.ensureVisible(pin);
      await tester.pumpAndSettle();
      expect(pin.hitTestable(), findsOneWidget, reason: place.id);
    }
    expect(find.byType(FilledButton).hitTestable(), findsOneWidget);
  });
}
