import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/declaration.dart';
import '../services/declaration_service.dart';
import '../services/declaration_observations.dart';
import '../services/profile_service.dart';
import '../services/personal_data_validator.dart';
import '../services/validation_service.dart';
import 'dashboard.dart' show AppointmentPage;
import 'declaration_views.dart';
import 'personal_profile_page.dart';
import 'superior_selector.dart';

class EditorPage extends StatefulWidget {
  final Declaration? existing;
  final int initialStep;
  final ValidationIssue? focusIssue;
  final bool showValidation;
  const EditorPage(
      {super.key,
      this.existing,
      this.initialStep = 0,
      this.focusIssue,
      this.showValidation = false});
  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final service = DeclarationService();
  final fields = List.generate(8, (_) => TextEditingController());
  final notes = TextEditingController();
  final jobs = <Appointment>[];
  final external = <Appointment>[];
  final scroll = ScrollController();
  late final String draftId;
  late int step;
  bool busy = false, loading = true, dirty = false, leaving = false;
  bool showErrors = false;
  String? error;
  static const steps = ['Datos', 'Nombramientos', 'Horarios', 'Resumen'];

  @override
  void initState() {
    super.initState();
    step = widget.initialStep;
    showErrors = widget.showValidation || step == 3;
    final d = widget.existing;
    draftId = d?.id ?? service.declarations.doc().id;
    if (d != null) {
      final values = [
        d.ownerName,
        d.identification,
        d.phone,
        d.email,
        d.unit,
        d.observations,
        d.periodId,
        d.superiorId
      ];
      for (var i = 0; i < values.length; i++) {
        fields[i].text = values[i];
      }
      jobs.addAll(d.appointments);
      external.addAll(d.externalJobs);
      notes.text = d.additionalObservations;
    }
    for (final f in [...fields, notes]) {
      f.addListener(_changed);
    }
    _loadProfile();
    final issue = widget.focusIssue;
    if (issue?.appointmentIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          appointment(issue!.external,
              index: issue.appointmentIndex, blockIndex: issue.blockIndex);
        }
      });
    }
  }

  void _changed() {
    if (!loading && mounted && !dirty) setState(() => dirty = true);
  }

  Future<void> _loadProfile({bool replace = false}) async {
    try {
      final profile = await ProfileService().load();
      if (!mounted) return;
      final keys = ['name', 'identification', 'phone', 'email', 'unit'];
      for (var i = 0; i < keys.length; i++) {
        if (replace || fields[i].text.isEmpty) {
          fields[i].text = '${profile[keys[i]] ?? ''}';
        }
      }
    } catch (_) {
      if (mounted) {
        error =
            'No se pudo cargar el perfil. Podés guardar y completar los datos después.';
      }
    }
    if (mounted) {
      setState(() {
        loading = false;
        if (replace) dirty = true;
      });
    }
  }

  Declaration snapshot() => Declaration(
        id: draftId,
        ownerId: FirebaseAuth.instance.currentUser!.uid,
        ownerName: PersonalDataValidator.normalizeName(fields[0].text),
        identification: fields[1].text.trim(),
        phone: fields[2].text.trim(),
        email: fields[3].text.trim(),
        unit: fields[4].text.trim(),
        periodId: fields[6].text,
        superiorId: fields[7].text,
        status: 'BORRADOR',
        observations: generateDeclarationSummary({
          'appointments': jobs.map((j) => j.toMap()).toList(),
          'externalJobs': external.map((j) => j.toMap()).toList()
        }),
        additionalObservations: notes.text.trim(),
        version: widget.existing?.version ?? 1,
        appointments: List.of(jobs),
        externalJobs: List.of(external),
        updatedAt: DateTime.now(),
      );

  Future<void> save() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await service.save(snapshot());
      if (!mounted) return;
      setState(() {
        dirty = false;
        leaving = true;
      });
      Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
              builder: (_) => DeclarationSummaryPage(id: result.id)));
    } catch (e) {
      if (mounted) {
        setState(() => error = e is StateError ? e.message : '$e');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> back() async {
    if (busy) return;
    if (dirty) {
      final choice = await showDialog<String>(
          context: context,
          builder: (c) => AlertDialog(
                title: const Text('Cambios sin guardar'),
                content: const Text(
                    'Podés guardar este avance aunque falten datos.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, 'cancel'),
                      child: const Text('Seguir editando')),
                  TextButton(
                      onPressed: () => Navigator.pop(c, 'discard'),
                      child: const Text('Descartar')),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, 'save'),
                      child: const Text('Guardar'))
                ],
              ));
      if (choice == 'save') {
        await save();
        return;
      }
      if (choice != 'discard') return;
    }
    if (!mounted) return;
    setState(() => leaving = true);
    Navigator.pop(context);
  }

  void go(int value) {
    setState(() {
      step = value;
      showErrors = showErrors || value == 3;
    });
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  Future<void> appointment(bool outside, {int? index, int? blockIndex}) async {
    final list = outside ? external : jobs;
    final value = await Navigator.push<Appointment>(
        context,
        MaterialPageRoute(
            builder: (_) => AppointmentPage(
                  existing: index == null ? null : list[index],
                  institutionalWorkplace:
                      outside ? null : 'Universidad de Costa Rica',
                  allowIncomplete: true,
                  initialBlockIndex: blockIndex,
                )));
    if (value != null && mounted) {
      setState(() {
        index == null ? list.add(value) : list[index] = value;
        dirty = true;
      });
    }
  }

  Widget field(int index, String label) {
    final validators = [
      PersonalDataValidator.name,
      PersonalDataValidator.identification,
      PersonalDataValidator.phone,
      PersonalDataValidator.email,
      PersonalDataValidator.unit
    ];
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: fields[index],
          readOnly: true,
          decoration: InputDecoration(
              labelText: label,
              errorMaxLines: 3,
              errorText:
                  showErrors ? validators[index](fields[index].text) : null),
        ));
  }

  Widget periods() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('periods')
          .where('enabled', isEqualTo: true)
          .snapshots(),
      builder: (c, s) {
        final docs = s.data?.docs ?? [];
        final current = fields[6].text;
        final ids = docs.map((d) => d.id).toSet();
        return DropdownButtonFormField<String>(
          key: ValueKey('period-$current-${ids.length}'),
          initialValue: current.isEmpty ? null : current,
          isExpanded: true,
          decoration: InputDecoration(
              labelText: 'Período activo',
              errorText: showErrors && current.isEmpty
                  ? 'Seleccioná un período.'
                  : null),
          items: [
            if (current.isNotEmpty && !ids.contains(current))
              DropdownMenuItem(
                  value: current, child: Text('$current (inactivo)')),
            ...docs.map((d) => DropdownMenuItem(
                value: d.id,
                child: Text('${d.data()['name'] ?? d.id}',
                    overflow: TextOverflow.ellipsis)))
          ],
          onChanged: busy
              ? null
              : (value) => setState(() {
                    fields[6].text = value ?? '';
                    dirty = true;
                  }),
        );
      });

  List<Widget> data() => [
        const Text('Datos del declarante',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text(
            'Los datos personales se toman de tu perfil. Podés guardar el avance y completarlos después.'),
        TextButton.icon(
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PersonalProfilePage()));
              if (mounted) await _loadProfile(replace: true);
            },
            icon: const Icon(Icons.person_outline),
            label: const Text('Completar o editar mis datos')),
        field(0, 'Nombre completo'),
        field(1, 'Identificación'),
        field(3, 'Correo electrónico'),
        field(2, 'Teléfono'),
        field(4, 'Unidad académica o administrativa'),
        periods(),
        const SizedBox(height: 16),
        SuperiorSelector(
            controller: fields[7],
            enabled: !busy,
            errorText: showErrors && fields[7].text.isEmpty
                ? 'Seleccioná un superior.'
                : null),
        TextField(
            controller: notes,
            maxLength: 2000,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
                labelText: 'Observaciones adicionales',
                helperText:
                    'Este texto se conserva aparte del resumen automático.')),
      ];

  List<Widget> appointments() => [
        for (final outside in [false, true]) ...[
          Text(outside ? 'Otras instituciones' : 'Nombramientos UCR',
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...List.generate((outside ? external : jobs).length, (i) {
            final job = (outside ? external : jobs)[i];
            return Card(
                child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                              job.workplace.isEmpty
                                  ? 'Institución pendiente'
                                  : job.workplace,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                              '${job.position.isEmpty ? 'Puesto pendiente' : job.position} · ${job.blocks.length} bloques'),
                          Wrap(spacing: 8, children: [
                            TextButton.icon(
                                onPressed: () => appointment(outside, index: i),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Editar')),
                            TextButton.icon(
                                onPressed: () => setState(() {
                                      (outside ? external : jobs).removeAt(i);
                                      dirty = true;
                                    }),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Quitar'))
                          ]),
                        ])));
          }),
          OutlinedButton.icon(
              onPressed: () => appointment(outside),
              icon: const Icon(Icons.add),
              label: Text(outside
                  ? 'Agregar institución externa'
                  : 'Agregar nombramiento UCR')),
          const SizedBox(height: 24),
        ],
      ];

  List<Widget> schedules() => [
        const Text('Horarios semanales',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const Text(
            'Lunes a sábado. Tocá un nombramiento para agregar o corregir sus intervalos.'),
        if (jobs.isEmpty && external.isEmpty)
          TextButton(
              onPressed: () => go(1),
              child: const Text('Agregar un nombramiento')),
        for (final outside in [false, true])
          ...List.generate((outside ? external : jobs).length, (i) {
            final job = (outside ? external : jobs)[i];
            return Card(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                              job.workplace.isEmpty
                                  ? 'Institución pendiente'
                                  : job.workplace,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          for (final b in job.blocks)
                            Text('${const [
                              '',
                              'Lunes',
                              'Martes',
                              'Miércoles',
                              'Jueves',
                              'Viernes',
                              'Sábado'
                            ][b.day]} ${b.start}–${b.end} · ${intervalDuration(b)}'),
                          TextButton.icon(
                              onPressed: () => appointment(outside, index: i),
                              icon: const Icon(Icons.schedule),
                              label: const Text('Editar horarios')),
                        ])));
          }),
        ScheduleValidationPanel(
            declaration: snapshot(),
            onCorrect: () => go(0),
            onIssue: (issue) {
              if (issue.appointmentIndex != null) {
                appointment(issue.external,
                    index: issue.appointmentIndex,
                    blockIndex: issue.blockIndex);
              } else {
                go(1);
              }
            }),
      ];

  List<Widget> review() => [
        const Text('Resumen antes de continuar',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const Text(
            'Estado: BORRADOR. Guardar no firma ni valida esta declaración.'),
        const SizedBox(height: 12),
        Text(
            '${fields[0].text}\n${fields[1].text}\n${fields[4].text}\nPeríodo: ${fields[6].text.isEmpty ? 'Pendiente' : fields[6].text}'),
        TextButton(onPressed: () => go(0), child: const Text('Corregir datos')),
        ...schedules(),
        const SizedBox(height: 16),
        const Text('Resumen automático',
            style: TextStyle(fontWeight: FontWeight.bold)),
        Text(snapshot().observations.isEmpty
            ? 'Pendiente de horarios'
            : snapshot().observations),
        const SizedBox(height: 12),
        const Text('Observaciones adicionales',
            style: TextStyle(fontWeight: FontWeight.bold)),
        Text(notes.text.isEmpty ? 'Sin observaciones adicionales' : notes.text),
      ];

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: leaving || !dirty,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) back();
        },
        child: Scaffold(
          appBar: AppBar(
              title: Text(widget.existing == null
                  ? 'Nueva declaración'
                  : 'Editar borrador'),
              leading: IconButton(
                  tooltip: 'Atrás',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: back)),
          body: SafeArea(
              child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(children: [
                        Padding(
                            padding: const EdgeInsets.all(12),
                            child: Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: List.generate(
                                    4,
                                    (i) => ChoiceChip(
                                        label: Text('${i + 1}. ${steps[i]}'),
                                        selected: step == i,
                                        onSelected: (_) => go(i))))),
                        if (loading) const LinearProgressIndicator(),
                        if (error != null)
                          Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(error!,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error))),
                        Expanded(
                            child: ListView(
                                controller: scroll,
                                padding: const EdgeInsets.all(16),
                                children: [
                              ...switch (step) {
                                0 => data(),
                                1 => appointments(),
                                2 => schedules(),
                                _ => review()
                              },
                              const SizedBox(height: 24),
                            ])),
                        Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                            child: Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                alignment: WrapAlignment.end,
                                children: [
                                  if (step > 0)
                                    TextButton(
                                        onPressed: () => go(step - 1),
                                        child: const Text('Anterior')),
                                  if (step < 3)
                                    OutlinedButton(
                                        onPressed: () => go(step + 1),
                                        child: const Text('Continuar')),
                                  FilledButton.icon(
                                      onPressed: busy || loading ? null : save,
                                      icon: const Icon(Icons.save_outlined),
                                      label: Text(busy
                                          ? 'Guardando...'
                                          : 'Guardar borrador')),
                                ])),
                      ])))),
        ),
      );

  @override
  void dispose() {
    for (final f in [...fields, notes]) {
      f.dispose();
    }
    scroll.dispose();
    super.dispose();
  }
}

String intervalDuration(TimeBlock block) {
  try {
    final minutes = ValidationService.minutes(block.end) -
        ValidationService.minutes(block.start);
    return minutes > 0
        ? '${minutes ~/ 60} h ${minutes % 60} min'
        : 'Intervalo inválido';
  } catch (_) {
    return 'Hora pendiente';
  }
}

class ScheduleValidationPanel extends StatelessWidget {
  final Declaration declaration;
  final VoidCallback? onCorrect;
  final ValueChanged<ValidationIssue>? onIssue;
  const ScheduleValidationPanel(
      {super.key, required this.declaration, this.onCorrect, this.onIssue});
  @override
  Widget build(BuildContext context) {
    final result = ValidationService.validate(
        declaration.appointments, declaration.externalJobs);
    final errors = [
      ...PersonalDataValidator.errors(declaration),
      if (declaration.periodId.isEmpty) 'Seleccioná un período.',
      if (declaration.superiorId.isEmpty) 'Seleccioná un superior.',
    ];
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                      'Horas institucionales: ${result.institutionalHours.toStringAsFixed(2)} / ${result.expectedHours.toStringAsFixed(2)} esperadas'),
                  Text(
                      'Horas externas: ${result.externalHours.toStringAsFixed(2)}'),
                  Text(
                      'Total registrado: ${(result.institutionalHours + result.externalHours).toStringAsFixed(2)} horas'),
                  const SizedBox(height: 8),
                  Text(
                      errors.isEmpty && result.valid
                          ? 'Sin errores locales. La validación final se realiza en el servidor.'
                          : 'Pendientes de corregir: ${errors.length + result.errors.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  for (final message in errors)
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text('• $message',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error))),
                  for (final issue in result.issues)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('• ${issue.message}',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                      subtitle: onIssue == null
                          ? null
                          : const Text('Tocá para corregir este problema'),
                      onTap: onIssue == null ? null : () => onIssue!(issue),
                    ),
                  if (errors.isNotEmpty && onCorrect != null)
                    TextButton.icon(
                        onPressed: onCorrect,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Corregir información')),
                ])));
  }
}

class DeclarationSummaryPage extends StatelessWidget {
  final String id;
  const DeclarationSummaryPage({super.key, required this.id});
  @override
  Widget build(BuildContext context) => DeclarationDetailPage(
      id: id,
      actionsBuilder: (d) =>
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ScheduleValidationPanel(
                declaration: d,
                onIssue: d.status == 'BORRADOR'
                    ? (issue) => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EditorPage(
                                existing: d,
                                initialStep:
                                    issue.appointmentIndex == null ? 1 : 2,
                                showValidation: true,
                                focusIssue: issue)))
                    : null,
                onCorrect: d.status == 'BORRADOR'
                    ? () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                EditorPage(existing: d, showValidation: true)))
                    : null),
            if (d.status == 'BORRADOR') ...[
              OutlinedButton.icon(
                  onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => EditorPage(existing: d))),
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar borrador')),
              FilledButton.icon(
                  onPressed: () async {
                    try {
                      await DeclarationService().transition(d, 'validate');
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('$e')));
                      }
                    }
                  },
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Validar declaración')),
            ],
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver a mis trámites')),
          ]));
}
