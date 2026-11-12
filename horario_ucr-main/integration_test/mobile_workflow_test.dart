import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:horario_ucr_integrador/main.dart' as app;
import 'package:horario_ucr_integrador/models/declaration.dart';
import 'package:horario_ucr_integrador/pages/dashboard.dart';
import 'package:horario_ucr_integrador/pages/declaration_editor.dart';
import 'package:horario_ucr_integrador/pages/admin_page.dart';
import 'package:horario_ucr_integrador/services/declaration_service.dart';
import 'package:horario_ucr_integrador/theme/ucr_theme.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Laboratorio Android y ciclo completo de los cuatro roles',
      (t) async {
    await app.main();
    final auth = FirebaseAuth.instance;
    final service = DeclarationService();
    final db = FirebaseFirestore.instance;
    Future<void> frames([int milliseconds = 1200]) async {
      await t.pump(Duration(milliseconds: milliseconds));
    }

    Future<void> login(String role) async {
      await auth.signOut();
      await t.pumpWidget(const SizedBox.shrink());
      await auth.signInWithEmailAndPassword(
          email: '$role@local.test', password: 'PruebaUCR2026!');
      await t.pumpWidget(const app.DeclaraApp());
      for (var i = 0;
          i < 60 && find.byType(Dashboard).evaluate().isEmpty;
          i++) {
        await frames(150);
      }
      await frames();
      expect(find.byType(Dashboard), findsOneWidget);
    }

    Future<void> show(Widget page) async {
      await t.pumpWidget(MaterialApp(
          theme: UcrTheme.light,
          locale: const Locale('es', 'ES'),
          supportedLocales: const [Locale('es', 'ES')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: page));
      await frames();
    }

    Future<void> screenshot(String name) async {
      await frames(700);
      await binding.takeScreenshot(name);
      // Pausa real para que el video permita leer los requisitos del laboratorio.
      await Future<void>.delayed(const Duration(seconds: 3));
    }

    Future<Declaration> stored(String id) async =>
        Declaration.fromDoc(await db.collection('declarations').doc(id).get());
    Future<void> action(String id, String name,
        {String note = '', bool confirmed = false}) async {
      await service.transition(await stored(id), name,
          note: note, confirmed: confirmed);
      await frames(300);
    }

    Declaration draft(String id, {bool conflict = false, int version = 1}) =>
        Declaration(
          id: id,
          ownerId: 'local-declarante',
          ownerName: 'Ana Laboratorio Móvil',
          identification: '111111111',
          phone: '88887777',
          email: 'declarante@local.test',
          unit: 'Escuela de Informática',
          periodId: '2026-II',
          superiorId: 'local-superior',
          status: 'BORRADOR',
          observations: '',
          additionalObservations: 'Observación del laboratorio Android.',
          version: version,
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
              blocks: [
                const TimeBlock(
                    day: 1,
                    start: '08:00',
                    end: '12:00',
                    activityName: 'Proyecto de laboratorio'),
                TimeBlock(
                    day: 1,
                    start: conflict ? '11:00' : '13:00',
                    end: '14:00',
                    activityName: 'Proyecto de laboratorio')
              ],
            )
          ],
        );
    await login('declarante');
    await binding.convertFlutterSurfaceToImage();
    await frames();
    debugPrint('VIDEO_READY');
    await frames(4000);
    await screenshot('01-inicio-android');

    // Guardado desde el formulario real sin nombramientos ni selección de período.
    await t.tap(find.byType(FloatingActionButton));
    await frames();
    expect(find.byType(EditorPage), findsOneWidget);
    await t.tap(find.widgetWithText(FilledButton, 'Guardar borrador'));
    await frames(2000);
    for (var i = 0;
        i < 60 && find.byType(DeclarationSummaryPage).evaluate().isEmpty;
        i++) {
      await frames(200);
    }
    final partialId = t
        .widget<DeclarationSummaryPage>(find.byType(DeclarationSummaryPage))
        .id;
    expect((await stored(partialId)).appointments, isEmpty);
    expect((await stored(partialId)).status, 'BORRADOR');
    binding.reportData ??= {};
    binding.reportData!['partialDraftId'] = partialId;

    final id = db.collection('declarations').doc().id;
    await service.save(draft(id, conflict: true));
    await show(EditorPage(existing: await stored(id), initialStep: 2));
    expect(find.textContaining('11:00–12:00'), findsOneWidget);
    await screenshot('02-horarios-conflicto');
    await expectLater(
        service.transition(await stored(id), 'validate'), throwsStateError);
    expect((await stored(id)).status, 'BORRADOR');
    await service.save(draft(id));
    await show(DeclarationSummaryPage(id: id));
    await t.ensureVisible(find.byType(ScheduleValidationPanel));
    await frames();
    await screenshot('03-resumen-corregido');
    await action(id, 'validate');
    await action(id, 'submit');
    await action(id, 'signOwner', confirmed: true);
    await action(id, 'route');
    await login('superior');
    await screenshot('04-superior-android');
    await action(id, 'return', note: 'Revisar las actividades registradas.');
    await login('declarante');
    await action(id, 'newVersion');
    expect((await stored(id)).version, 2);
    await service.save(draft(id, version: 2));
    await action(id, 'validate');
    await action(id, 'submit');
    await action(id, 'signOwner', confirmed: true);
    await action(id, 'route');
    await login('superior');
    await action(id, 'signSuperior');
    await action(id, 'sendHr');
    await login('rrhh');
    await screenshot('05-rrhh-android');
    await action(id, 'receive');
    await action(id, 'finish');
    await service.archivePdf(await stored(id));
    final pdf = await FirebaseFunctions.instanceFor(region: 'us-east1')
        .httpsCallable('downloadDeclarationPdf')
        .call({'declarationId': id, 'version': 2});
    expect(base64Decode(pdf.data['pdfBase64'] as String).take(4).toList(),
        [37, 80, 68, 70]);
    binding.reportData!['pdfBase64'] = pdf.data['pdfBase64'];
    binding.reportData!['finalDeclarationId'] = id;
    await login('admin');
    await show(const AdminPage());
    await screenshot('06-administracion-android');
    expect(find.text('Usuarios'), findsOneWidget);
    await login('declarante');
    expect((await stored(partialId)).appointments, isEmpty);
    binding.reportData!['completed'] = true;
  }, timeout: const Timeout(Duration(minutes: 5)));
}
