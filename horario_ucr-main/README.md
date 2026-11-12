# DeclaraUCR — Declaraciones juradas de horario

Proyecto académico de la Universidad de Costa Rica, desarrollado en Flutter Web con Firebase. Permite declarar horarios laborales, validarlos, obtener las firmas internas del declarante y su superior, y tramitar la recepción y finalización en Recursos Humanos.

## Usarlo en esta PC

1. Hacé doble clic en **Iniciar-DeclaraUCR.cmd**. Está disponible tanto en la carpeta abierta en VS Code como dentro de la carpeta del proyecto.
2. Esperá el mensaje «Aplicación lista». El inicio compila la aplicación y abre el navegador en **http://127.0.0.1:7357**.
3. Ingresá con una de estas cuentas de prueba:

| Cuenta | Rol |
| --- | --- |
| `declarante@local.test` | Crear horarios, validar, firmar y consultar sus declaraciones |
| `superior@local.test` | Revisar, devolver, firmar y enviar a RRHH |
| `rrhh@local.test` | Recibir, finalizar y archivar PDF |
| `admin@local.test` | Administrar usuarios y períodos |

**Contraseña para las cuatro cuentas:** `PruebaUCR2026!`

Para cerrar, ejecutá **Detener-DeclaraUCR.cmd**. Este acceso guarda los datos antes de apagar los servicios. El siguiente inicio recupera las cuentas, declaraciones y archivos guardados. Apagar Windows sin usar ese acceso puede perder los cambios realizados desde el último guardado.

El entorno usa el proyecto ficticio `demo-declaraucr-local`, escucha únicamente en la propia PC y muestra «PRUEBA LOCAL» en pantalla. No necesita iniciar sesión en Firebase ni usa las cuentas de prueba en el proyecto de Internet. La primera preparación necesita Internet para descargar dependencias y recursos de Flutter/Firebase.

La consola local para inspeccionar cuentas y datos está en **http://127.0.0.1:4000** mientras los servicios estén encendidos.

Al recargar o cerrar la pestaña se vuelve a pedir el inicio de sesión. Las cuentas y los datos se conservan; esta sesión temporal evita un problema de restauración de credenciales del SDK de Firebase al usar emuladores.

## Qué hace

- Registro, inicio de sesión, recuperación de contraseña y edición del perfil.
- Nombramientos UCR y trabajos en otras instituciones; fechas, jornada y bloques de lunes a sábado.
- Cargos y fracciones de jornada UCR; detalle de actividades y cursos cuando corresponde.
- Validación de traslapes, horas esperadas, exclusión de 12:00–13:00 y máximo diario de diez horas.
- Borradores, validación, firmas internas, revisión del superior, devoluciones, versiones y trámite en RRHH.
- Historial de movimientos, observaciones, notificaciones y generación/archivo de PDF.
- Administración de roles y períodos académicos.

El flujo principal es:

`BORRADOR → VALIDADA → PENDIENTE_FIRMA_DECLARANTE → FIRMADA_POR_DECLARANTE → PENDIENTE_FIRMA_SUPERIOR → FIRMADA_POR_SUPERIOR → ENVIADA_A_RRHH → RECIBIDA_RRHH → FINALIZADA`

El superior también puede devolver una declaración para corregirla en una nueva versión.

## Estructura y herramientas

El código está en esta carpeta, que contiene `pubspec.yaml`. En esta PC su ruta es `C:\Development\horario_ucr-main\horario_ucr-main`.

| Carpeta o archivo | Responsabilidad |
| --- | --- |
| `lib/main.dart` | Inicio, acceso y registro |
| `lib/pages/` | Paneles, formularios, perfiles, administración y seguimiento |
| `lib/services/` | Validaciones, flujo de declaraciones, PDF y notificaciones |
| `lib/models/` | Declaraciones, nombramientos y bloques horarios |
| `functions/` | Funciones de servidor que validan y guardan declaraciones y PDF |
| `websocket_server/` | Notificaciones autenticadas en tiempo real |
| `firestore.rules`, `storage.rules` | Reglas de acceso a los datos y archivos |
| `firebase.local.json` | Puertos y servicios del entorno local |
| `scripts/seed-local.cjs` | Cuentas, período y declaración de ejemplo |
| `.local/` | Registros de ejecución y datos locales guardados |

Se comprobó con Flutter 3.47.9, Dart 3.13.7, Node 24.19.0, Firebase CLI 15.34.0 y Java 21. La configuración local usa Node 24; el despliegue original de Functions sigue configurado para Node 22.

## Desarrollo desde VS Code

En **Terminal → Ejecutar tarea** están disponibles los accesos para iniciar, detener y comprobar el entorno local. Los comandos de Flutter deben ejecutarse desde la carpeta que contiene `pubspec.yaml`.

Para depurar los cambios en Chrome, primero iniciá los servicios locales y luego ejecutá:

```powershell
flutter run -d chrome --web-hostname 127.0.0.1 --web-port 7358 --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=NOTIFICATIONS_WS_URL=ws://127.0.0.1:8080
```

La vista de desarrollo usa el puerto 7358 para compartir los servicios del entorno local que sirve la versión compilada en el 7357.

## Comprobaciones

```powershell
flutter analyze --no-pub
flutter test --no-pub
node --test security_tests/backend_validator.test.cjs
# Con el entorno local encendido:
node scripts/check-local.cjs
```

El 11 de noviembre de 2026 pasaron las 96 pruebas Flutter y las 67 pruebas del validador del servidor. El análisis Flutter terminó sin problemas. La comprobación integral local verificó las cuatro cuentas, listado de superiores, autenticación WebSocket, guardado, validación, firmas, recepción y finalización en RRHH, y transporte de PDF con verificación de su huella. Esta última prueba genera una declaración adicional de comprobación; usa un PDF sencillo para probar almacenamiento y descarga, no el diseño del formulario institucional.

## Firebase de Internet

La configuración original está en `lib/firebase_options.dart` y `firebase.json`. Ejecutar Flutter sin `USE_FIREBASE_EMULATORS=true` conecta esa configuración. Los accesos de inicio local siempre habilitan explícitamente los emuladores.

No se desplegaron cambios en Internet. El estado actual de los servicios del proyecto original no se verificó. Las firmas son internas y no equivalen a firmas digitales certificadas. La correspondencia exacta del PDF con el formulario institucional y una auditoría completa de seguridad quedan fuera de las comprobaciones realizadas.
