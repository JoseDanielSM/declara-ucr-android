# Plan de pruebas

## Verificación local del 11 de noviembre de 2026

- `flutter analyze --no-pub`: sin problemas.
- `flutter test --no-pub`: 96 pruebas aprobadas.
- `node --test security_tests/backend_validator.test.cjs`: 67 pruebas aprobadas.
- `node scripts/check-local.cjs`, con los emuladores encendidos: 12 comprobaciones integrales aprobadas. Crea una declaración de prueba adicional, recorre los cuatro roles y prueba notificaciones y archivo/descarga de un PDF sencillo.
- Cierre con exportación y reinicio con importación: cuentas, declaración finalizada y PDF recuperados.

Consultar el README para iniciar los servicios y localizar los registros actuales en `.local/`.

## Plan y evidencias anteriores

Ejecutar `flutter test` tras instalar dependencias.

Casos manuales: autenticación; alta de declaración en período activo; bloqueo de período inactivo; registro de dos nombramientos; cruce entre empleo interno y externo; horas invertidas; exclusión 12:00–13:00; límite de 10 horas; diferencia de jornada; firma confirmada; rechazo sin observación; creación de versión; historial; recepción y cierre; PDF y permisos entre roles.

**Evidencias reales:** pendientes de ejecución. No se adjuntan capturas inventadas.

## Resultados de pruebas automatizadas

**Fecha:** 20 de octubre de 2026

**Comando:** `flutter test`
**Resultado:** All tests passed!

**Comando:** `flutter analyze`
**Resultado:** No issues found!

**Conclusión:** Las pruebas automatizadas existentes se ejecutaron correctamente y el análisis estático no reportó problemas. Estos resultados no sustituyen las pruebas de seguridad ni la validación integral de todas las historias de usuario.
