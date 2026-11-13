import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horario_ucr_integrador/pages/declaration_summary_card.dart';
import 'package:horario_ucr_integrador/theme/ucr_theme.dart';
import 'package:horario_ucr_integrador/theme/ucr_colors.dart';

void main() {
  const statuses = [
    'BORRADOR',
    'VALIDADA',
    'PENDIENTE_FIRMA_SUPERIOR',
    'FINALIZADA',
    'ANULADA'
  ];
  test(
      'Los filtros representan los contadores y mantienen los resultados vacíos',
      () {
    List<String> filter(String name) =>
        statuses.where((s) => matchesDeclarationStatus(s, name)).toList();
    expect(filter('TODOS'), statuses);
    expect(filter('PENDIENTES'),
        ['BORRADOR', 'VALIDADA', 'PENDIENTE_FIRMA_SUPERIOR']);
    expect(filter('FINALIZADA'), ['FINALIZADA']);
    expect(filter('BORRADOR'), ['BORRADOR']);
    expect(['VALIDADA'].where((s) => matchesDeclarationStatus(s, 'BORRADOR')),
        isEmpty);
  });
  for (final width in [320.0, 360.0, 600.0]) {
    testWidgets('Tarjeta accesible y pulsable a $width dp con texto ampliado',
        (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = Size(width, 900);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetPhysicalSize);
      var taps = 0;
      await t.pumpWidget(MaterialApp(
          theme: UcrTheme.light,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!),
          home: Scaffold(
              body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: DeclarationSummaryCard(
                      label: 'Total de declaraciones',
                      count: 0,
                      accent: UcrColors.blue,
                      onTap: () => taps++)))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      final semantics = t.ensureSemantics();
      expect(
          t.getSemantics(find.byType(DeclarationSummaryCard)),
          matchesSemantics(
              label:
                  'Total de declaraciones: 0. Abrir trámites con este filtro',
              isButton: true,
              hasSelectedState: true,
              hasTapAction: true));
      semantics.dispose();
      await t.tap(find.byType(DeclarationSummaryCard));
      await t.pump();
      expect(taps, 1);
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pump();
      expect(taps, 2);
    });
  }
}
