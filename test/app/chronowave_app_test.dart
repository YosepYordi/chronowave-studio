import 'package:flutter_test/flutter_test.dart';
import 'package:chronowave_studio/src/app/chronowave_app.dart';
import 'package:chronowave_studio/src/core/database/database.dart';

void main() {
  setUp(() {
    // Asegurar que la base de datos se ejecute en modo mock simulado para los tests de widgets
    AppDatabase.isTesting = true;
  });

  testWidgets('shows the ChronoWave technical starting point in Spanish', (
    tester,
  ) async {
    await tester.pumpWidget(const ChronoWaveApp());
    await tester.pumpAndSettle();

    // Validar encabezado del Home
    expect(find.text('ChronoWave'), findsOneWidget);
    expect(find.text('Studio Engine v0.1.0'), findsOneWidget);

    // Al no haber proyectos, debe mostrar el estado vacío premium
    expect(find.text('Sin Proyectos Aún'), findsOneWidget);
    expect(find.text('Crear Espacio'), findsOneWidget);
  });

  testWidgets('navigates through the phase one localized workspace sections', (
    tester,
  ) async {
    await tester.pumpWidget(const ChronoWaveApp());
    await tester.pumpAndSettle();

    // Validar etiquetas de navegación inferior en español
    expect(find.text('Proyectos'), findsOneWidget);
    expect(find.text('Editor'), findsOneWidget);
    expect(find.text('Exportar'), findsOneWidget);
    expect(find.text('Ajustes'), findsOneWidget);

    // Navegar al Editor (Inactivo)
    await tester.tap(find.text('Editor'));
    await tester.pumpAndSettle();
    expect(find.text('Editor de Video Inactivo'), findsOneWidget);
    expect(find.text('Ver biblioteca de proyectos'), findsOneWidget);

    // Navegar a Exportar
    await tester.tap(find.text('Exportar'));
    await tester.pumpAndSettle();
    expect(find.text('Exportar Video'), findsOneWidget);
    expect(find.text('INICIAR EXPORTACIÓN'), findsOneWidget);

    // Navegar a Ajustes
    await tester.tap(
      find.text('Ajustes').last,
    ); // Tocar la pestaña en el nav bar (último)
    await tester.pumpAndSettle();
    expect(find.text('Configuración del estudio y hardware'), findsOneWidget);
    expect(find.text('Diagnósticos del Motor'), findsOneWidget);
  });
}
