import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horario_ucr_integrador/models/declaration.dart';
import 'package:horario_ucr_integrador/pages/declaration_editor.dart';
import 'package:horario_ucr_integrador/services/declaration_observations.dart';
import 'package:horario_ucr_integrador/services/validation_service.dart';
import 'package:horario_ucr_integrador/theme/ucr_theme.dart';
import 'package:horario_ucr_integrador/main.dart' as app;

Appointment fixture(bool conflict) => Appointment(
        workplace: 'Universidad de Costa Rica',
        position: 'Proyectos',
        expectedHours: 5,
        workloadFraction: '1/8',
        startDate: '2026-08-01',
        endDate: '2026-12-31',
        blocks: [
          const TimeBlock(
              day: 1,
              start: '08:00',
              end: '12:00',
              activityName: 'Laboratorio'),
          TimeBlock(
              day: 1,
              start: conflict ? '11:00' : '13:00',
              end: '14:00',
              activityName: 'Laboratorio'),
        ]);
Declaration draft() => Declaration(
    id: 'test',
    ownerId: 'owner',
    ownerName: '',
    identification: '',
    phone: '',
    email: '',
    unit: '',
    periodId: '',
    superiorId: '',
    status: 'BORRADOR',
    observations: '',
    additionalObservations: 'Texto propio',
    version: 1,
    appointments: [fixture(true)],
    externalJobs: [],
    updatedAt: DateTime(2026));

void main() {
  test('Caso obligatorio identifica día y ambos bloques del traslape', () {
    final result = ValidationService.validate([fixture(true)], []);
    expect(result.valid, isFalse);
    final issue =
        result.issues.firstWhere((i) => i.message.contains('traslape'));
    expect(issue.day, 1);
    expect(issue.blockIndex, 0);
    expect(issue.otherBlockIndex, 1);
    expect(issue.message, contains('11:00–12:00'));
    expect(ValidationService.validate([fixture(false)], []).valid, isTrue);
  });
  test('PDF conserva el texto escrito separado del resumen', () {
    final text = declarationPdfObservations({
      'observations': 'Resumen automático',
      'additionalObservations': 'Texto propio'
    });
    expect(text, contains('Resumen automático'));
    expect(text, contains('Texto propio'));
    expect(declarationPdfObservations({'observations': 'Versión antigua'}),
        'Versión antigua');
  });
  for (final width in [320.0, 360.0, 600.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Acceso $width dp, escala $scale, con teclado',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(
            theme: UcrTheme.light,
            builder: (context, child) => MediaQuery(
                data: MediaQueryData(
                    size: Size(width, 900),
                    textScaler: TextScaler.linear(scale),
                    viewInsets: const EdgeInsets.only(bottom: 300)),
                child: child!),
            home: const app.LoginPage()));
        await tester.pumpAndSettle();
        expect(find.text('Iniciar sesión'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
      testWidgets('Resumen $width dp, escala $scale, con teclado',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(
            theme: UcrTheme.light,
            home: MediaQuery(
                data: MediaQueryData(
                    size: Size(width, 900),
                    textScaler: TextScaler.linear(scale),
                    viewInsets: const EdgeInsets.only(bottom: 300)),
                child: Scaffold(
                    body: SingleChildScrollView(
                        child: ScheduleValidationPanel(
                            declaration: draft(), onCorrect: () {}))))));
        await tester.pumpAndSettle();
        expect(find.textContaining('11:00–12:00'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
