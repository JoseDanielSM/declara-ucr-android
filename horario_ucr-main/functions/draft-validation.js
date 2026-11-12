'use strict';

const { ScheduleValidationError } = require('./schedule-validation');
const personalFields = ['ownerName', 'identification', 'phone', 'email', 'unit', 'additionalObservations'];
const maxLengths = { ownerName: 100, identification: 9, phone: 8, email: 254, unit: 150, additionalObservations: 2000 };

function normalizeDraft(input) {
  const fail = message => { throw new ScheduleValidationError(message); };
  const text = (value, label, maximum = 150) => {
    if (value === undefined) return '';
    if (typeof value !== 'string' || value.length > maximum) fail(`${label}: texto inválido o demasiado largo.`);
    return value.trim();
  };
  const list = (value, label, maximum) => {
    if (value === undefined) return [];
    if (!Array.isArray(value) || value.length > maximum) fail(`${label}: lista inválida o demasiado grande.`);
    return value;
  };
  const allowed = ['id', 'version', 'periodId', 'superiorId', 'observations', 'appointments', 'externalJobs', ...personalFields];
  if (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).some(key => !allowed.includes(key))) fail('Datos o campos de borrador inválidos.');
  if (Buffer.byteLength(JSON.stringify(input), 'utf8') > 500000) fail('El borrador supera el tamaño permitido.');
  // Se valida por compatibilidad con los clientes; el servidor genera el resumen.
  text(input.observations, 'Resumen', 2000);
  const result = {};
  for (const field of personalFields) result[field] = text(input[field], field, maxLengths[field]);
  result.periodId = text(input.periodId, 'Período', 128);
  result.superiorId = text(input.superiorId, 'Superior', 128);
  for (const field of ['appointments', 'externalJobs']) {
    result[field] = list(input[field], field, 40).map(job => {
      if (!job || typeof job !== 'object' || Array.isArray(job)) fail('Nombramiento inválido.');
      const normalized = {};
      for (const key of ['workplace', 'position', 'startDate', 'endDate']) normalized[key] = text(job[key], key);
      const hours = job.expectedHours === undefined ? 0 : job.expectedHours;
      if (typeof hours !== 'number' || !Number.isFinite(hours) || hours < 0 || hours > 168) fail('Jornada inválida: usá un número entre 0 y 168.');
      normalized.expectedHours = hours;
      if (job.workloadFraction != null) normalized.workloadFraction = text(job.workloadFraction, 'Jornada', 10);
      normalized.blocks = list(job.blocks, 'Bloques horarios', 72).map(block => {
        if (!block || typeof block !== 'object' || Array.isArray(block) || !Number.isInteger(block.day) || block.day < 1 || block.day > 6) fail('Día inválido: usá lunes a sábado.');
        const value = { day: block.day, start: text(block.start, 'Inicio', 5), end: text(block.end, 'Fin', 5) };
        for (const key of ['courseCode', 'activityType', 'activityName']) {
          if (block[key] != null) value[key] = text(block[key], key, key === 'courseCode' ? 20 : 150);
        }
        return value;
      });
      return normalized;
    });
  }
  return result;
}

module.exports = { normalizeDraft };
