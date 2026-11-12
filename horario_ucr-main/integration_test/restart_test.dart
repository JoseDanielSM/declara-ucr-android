import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:horario_ucr_integrador/main.dart' as app;
import 'package:horario_ucr_integrador/models/declaration.dart';
import 'package:horario_ucr_integrador/pages/dashboard.dart';
import 'package:horario_ucr_integrador/pages/declaration_editor.dart';
import 'package:horario_ucr_integrador/services/declaration_service.dart';
import 'package:horario_ucr_integrador/theme/ucr_theme.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Reapertura real, adaptación del editor y completar el borrador',
      (t) async {
    await app.main();
    await t.pumpWidget(const SizedBox.shrink());
    final auth = FirebaseAuth.instance;
    await auth.signOut();
    await auth.signInWithEmailAndPassword(
        email: 'declarante@local.test', password: 'PruebaUCR2026!');
    final service = DeclarationService();
    final id = const String.fromEnvironment('CHECK_DRAFT_ID');
    expect(id, isNotEmpty);
    final ref = FirebaseFirestore.instance.collection('declarations').doc(id);
    final restored = Declaration.fromDoc(await ref.get());
    expect(restored.status, 'BORRADOR');
    expect(restored.appointments, isEmpty);
    expect(restored.ownerName, isNotEmpty);
    expect(restored.periodId, isEmpty);

    Future<void> show(Widget child, {double scale = 1}) async {
      await t.pumpWidget(MaterialApp(
        theme: UcrTheme.light,
        debugShowCheckedModeBanner: false,
        locale: const Locale('es', 'ES'),
        supportedLocales: const [Locale('es', 'ES')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: child,
      ));
      await t.pump(const Duration(seconds: 2));
    }

    await show(EditorPage(existing: restored, initialStep: 3));
    await binding.convertFlutterSurfaceToImage();
    await t.pump();
    await binding.takeScreenshot('07-borrador-recuperado');
    await t.tap(find.text('1. Datos'));
    await t.pump();
    await t.scrollUntilVisible(find.text('Seleccioná un período.'), 250,
        scrollable: find.byType(Scrollable).first, maxScrolls: 30);
    expect(find.text('Seleccioná un período.'), findsOneWidget);
    await t.scrollUntilVisible(find.text('Seleccioná un superior.'), 200,
        scrollable: find.byType(Scrollable).first, maxScrolls: 10);
    expect(find.text('Seleccioná un superior.'), findsOneWidget);
    final sizes = <String>[];
    final pixelRatio = t.view.devicePixelRatio;
    for (final width in [320.0, 360.0, 600.0]) {
      t.view.physicalSize = Size(width * pixelRatio, 900 * pixelRatio);
      for (final scale in [1.0, 2.0]) {
        // Incluye el encabezado, los cuatro pasos, los controles inferiores y teclado real.
        await show(EditorPage(key: UniqueKey(), existing: restored),
            scale: scale);
        final notes = find.byWidgetPredicate((w) =>
            w is TextField &&
            w.decoration?.labelText == 'Observaciones adicionales');
        await t.scrollUntilVisible(notes, 250,
            scrollable: find.byType(Scrollable).first, maxScrolls: 30);
        await t.showKeyboard(notes);
        await t.pump(const Duration(milliseconds: 500));
        expect(t.takeException(), isNull,
            reason: 'Editor $width dp / texto $scale / teclado');
        FocusManager.instance.primaryFocus?.unfocus();
        await t.pump();
        await show(AppointmentPage(key: UniqueKey(), allowIncomplete: true),
            scale: scale);
        await t.pump(const Duration(milliseconds: 500));
        expect(t.takeException(), isNull,
            reason: 'Nombramiento $width dp / texto $scale');
        sizes.add('$width dp / texto $scale / teclado');
      }
    }
    t.view.resetPhysicalSize();
    final complete = Declaration(
      id: id,
      ownerId: restored.ownerId,
      ownerName: restored.ownerName,
      identification: restored.identification,
      phone: restored.phone,
      email: restored.email,
      unit: restored.unit,
      periodId: '2026-II',
      superiorId: 'local-superior',
      status: 'BORRADOR',
      observations: '',
      additionalObservations:
          'Borrador recuperado tras cerrar Android y completado.',
      version: restored.version,
      updatedAt: DateTime.now(),
      externalJobs: [],
      appointments: [
        Appointment(
            workplace: 'Universidad de Costa Rica',
            position: 'Proyectos',
            workloadFraction: '1/8',
            expectedHours: 5,
            startDate: '2026-08-01',
            endDate: '2026-12-31',
            blocks: const [
              TimeBlock(
                  day: 1,
                  start: '08:00',
                  end: '12:00',
                  activityName: 'Proyecto de laboratorio'),
              TimeBlock(
                  day: 1,
                  start: '13:00',
                  end: '14:00',
                  activityName: 'Proyecto de laboratorio'),
            ])
      ],
    );
    final save = await service.save(complete);
    expect(save.id, id);
    final retry = await service.save(complete);
    expect(retry.id, id);
    expect(retry.saved, isFalse);
    await service.transition(Declaration.fromDoc(await ref.get()), 'validate');
    expect((await ref.get()).data()!['status'], 'VALIDADA');
    await show(DeclarationSummaryPage(id: id));
    await binding.takeScreenshot('08-borrador-completado-validado');
    binding.reportData = {
      ...?binding.reportData,
      'draftId': id,
      'restoredAfterProcessStop': true,
      'sameIdAfterRetry': true,
      'requiredFieldErrorsVisible': true,
      'finalStatus': 'VALIDADA',
      'layoutCases': sizes,
      'completed': true
    };
  }, timeout: const Timeout(Duration(minutes: 5)));
}
