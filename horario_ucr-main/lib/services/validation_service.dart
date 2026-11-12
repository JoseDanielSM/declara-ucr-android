import '../models/declaration.dart';

class ValidationIssue {
  final String message;
  final int? day,
      appointmentIndex,
      blockIndex,
      otherAppointmentIndex,
      otherBlockIndex;
  final bool external, otherExternal;
  const ValidationIssue(this.message,
      {this.day,
      this.appointmentIndex,
      this.blockIndex,
      this.otherAppointmentIndex,
      this.otherBlockIndex,
      this.external = false,
      this.otherExternal = false});
}

class ValidationResult {
  final List<String> errors;
  final double institutionalHours;
  final double externalHours;
  final double expectedHours;
  final List<ValidationIssue> issues;

  bool get valid => errors.isEmpty;

  const ValidationResult(this.errors, this.institutionalHours,
      this.externalHours, this.expectedHours,
      [this.issues = const []]);
}

class ValidationService {
  // Evita que Dart convierta fechas inexistentes en otras fechas.
  static DateTime? parseDate(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return null;
    }
    final year = int.parse(value.substring(0, 4));
    final month = int.parse(value.substring(5, 7));
    final day = int.parse(value.substring(8, 10));
    if (year < 1 || month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  static int minutes(String time) {
    final parts = time.split(':');

    if (parts.length != 2) {
      throw const FormatException('Hora inválida');
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      throw const FormatException('Hora inválida');
    }

    return hour * 60 + minute;
  }

  static String formatMinutes(int value) {
    final hour = (value ~/ 60).toString().padLeft(2, '0');
    final minute = (value % 60).toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  static ValidationResult validate(
    List<Appointment> jobs,
    List<Appointment> external,
  ) {
    final errors = <String>[];
    final issues = <ValidationIssue>[];

    final byDay = <int,
        List<
            ({
              int start,
              int end,
              String source,
              int jobIndex,
              int blockIndex,
              bool external
            })>>{};

    double internal = 0;
    double outside = 0;
    double expected = 0;

    if (jobs.isEmpty) {
      errors.add('Debe registrar al menos un nombramiento institucional.');
    }

    final allJobs = [
      ...jobs.map((job) => (job: job, external: false)),
      ...external.map((job) => (job: job, external: true)),
    ];

    for (var jobNumber = 0; jobNumber < allJobs.length; jobNumber++) {
      final entry = allJobs[jobNumber];
      final job = entry.job;
      final jobIndex = entry.external ? jobNumber - jobs.length : jobNumber;
      void problem(String message, {int? blockIndex, int? day}) {
        errors.add(message);
        issues.add(ValidationIssue(message,
            appointmentIndex: jobIndex,
            external: entry.external,
            blockIndex: blockIndex,
            day: day));
      }

      if (job.workplace.trim().isEmpty ||
          job.position.trim().isEmpty ||
          job.startDate.isEmpty ||
          job.endDate.isEmpty) {
        problem('Complete los datos del nombramiento: ${job.workplace}.');
      }

      final startDate = parseDate(job.startDate);
      final endDate = parseDate(job.endDate);

      final noEndDate = job.endDate.trim().toLowerCase() == 'no aplica';

      if (startDate == null ||
          (!noEndDate && (endDate == null || endDate.isBefore(startDate)))) {
        problem('Vigencia inválida en ${job.workplace}.');
      }

      final validExpectedHours =
          job.expectedHours.isFinite && job.expectedHours > 0;
      if (!validExpectedHours) {
        problem(
          'La jornada debe ser un número finito mayor que cero '
          'en ${job.workplace}.',
        );
      }

      if (!entry.external && validExpectedHours) {
        expected += job.expectedHours;
      }

      if (job.blocks.isEmpty) {
        problem('Agregue al menos un horario a ${job.workplace}.');
      }

      for (var blockIndex = 0; blockIndex < job.blocks.length; blockIndex++) {
        final block = job.blocks[blockIndex];
        try {
          final start = minutes(block.start);
          final end = minutes(block.end);

          if (block.day < 1 || block.day > 6) {
            problem('Solo se admiten horarios de lunes a sábado.',
                blockIndex: blockIndex, day: block.day);
            continue;
          }

          if (end <= start) {
            problem(
              'La hora final debe ser posterior a la inicial '
              '(${job.workplace}).',
              blockIndex: blockIndex,
              day: block.day,
            );
            continue;
          }

          if (start < 780 && end > 720) {
            problem(
              'Horario excluido de 12:00 a 13:00 '
              'en ${job.workplace}.',
              blockIndex: blockIndex,
              day: block.day,
            );
          }

          byDay.putIfAbsent(block.day, () => []).add((
            start: start,
            end: end,
            source: job.workplace,
            jobIndex: jobIndex,
            blockIndex: blockIndex,
            external: entry.external,
          ));

          final hours = (end - start) / 60;

          if (entry.external) {
            outside += hours;
          } else {
            internal += hours;
          }
        } catch (_) {
          problem('Formato de hora inválido en ${job.workplace}.',
              blockIndex: blockIndex, day: block.day);
        }
      }
    }

    for (final entry in byDay.entries) {
      final blocks = entry.value;

      blocks.sort((a, b) => a.start.compareTo(b.start));

      // Calcular minutos únicos, sin duplicar traslapes.
      int totalMinutes = 0;
      int? currentStart;
      int? currentEnd;

      for (final block in blocks) {
        if (currentStart == null || currentEnd == null) {
          currentStart = block.start;
          currentEnd = block.end;
        } else if (block.start <= currentEnd) {
          if (block.end > currentEnd) {
            currentEnd = block.end;
          }
        } else {
          totalMinutes += currentEnd - currentStart;
          currentStart = block.start;
          currentEnd = block.end;
        }
      }

      if (currentStart != null && currentEnd != null) {
        totalMinutes += currentEnd - currentStart;
      }

      if (totalMinutes > 600) {
        final message =
            'Día ${entry.key}: excede el máximo de 10 horas declaradas.';
        errors.add(message);
        issues.add(ValidationIssue(message,
            day: entry.key,
            appointmentIndex: blocks.first.jobIndex,
            blockIndex: blocks.first.blockIndex,
            external: blocks.first.external));
      }

      // Detectar traslapes internos y externos.
      for (var i = 1; i < blocks.length; i++) {
        for (var j = 0; j < i; j++) {
          final first = blocks[j];
          final second = blocks[i];

          if (first.end > second.start && second.end > first.start) {
            final overlapStart =
                first.start > second.start ? first.start : second.start;

            final overlapEnd = first.end < second.end ? first.end : second.end;

            final message = 'Día ${entry.key}: traslape '
                '${formatMinutes(overlapStart)}–'
                '${formatMinutes(overlapEnd)} '
                'entre ${first.source} (bloque ${first.blockIndex + 1}) y ${second.source} (bloque ${second.blockIndex + 1}).';
            errors.add(message);
            issues.add(ValidationIssue(message,
                day: entry.key,
                appointmentIndex: first.jobIndex,
                blockIndex: first.blockIndex,
                external: first.external,
                otherAppointmentIndex: second.jobIndex,
                otherBlockIndex: second.blockIndex,
                otherExternal: second.external));
          }
        }
      }
    }

    if ((internal - expected).abs() > 0.001) {
      errors.add(
        'Jornada institucional: '
        'esperadas ${expected.toStringAsFixed(2)} h, '
        'declaradas ${internal.toStringAsFixed(2)} h, '
        'diferencia ${(internal - expected).toStringAsFixed(2)} h.',
      );
    }

    return ValidationResult(errors, internal, outside, expected, [
      ...issues,
      for (final message in errors
          .where((message) => !issues.any((issue) => issue.message == message)))
        ValidationIssue(message),
    ]);
  }
}
