import 'package:chronowave_studio/src/app/chronowave_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the ChronoWave technical starting point', (tester) async {
    await tester.pumpWidget(const ChronoWaveApp());

    expect(find.text('ChronoWave Studio'), findsOneWidget);
    expect(find.text('Android first'), findsOneWidget);
    expect(find.text('Flutter + Rust + GStreamer/GES'), findsOneWidget);
    expect(find.text('Local projects ready for future sync'), findsOneWidget);
  });
}
