# DeclaraUCR — Declaraciones juradas de horario

Proyecto académico de la Universidad de Costa Rica, desarrollado en **Flutter para Android y web**, con Firebase. Permite declarar horarios laborales, guardar borradores incompletos, validarlos, registrar firmas electrónicas internas y tramitar la recepción y finalización en Recursos Humanos.

La implementación del laboratorio, decisiones visuales, pruebas y matriz de cumplimiento se documentan en [Laboratorio Android](documentation/Laboratorio_Android.md). El documento fuente es `Laboratorio_Desarrollo_Movil_Declaracion_Jurada_UCR.pdf`, proporcionado por el usuario; el alcance adicional de cuatro roles fue solicitado expresamente en el plan.

## Usarlo en esta PC

**Android:** hacé doble clic en **Iniciar-DeclaraUCR-Android.cmd**, en la carpeta abierta en VS Code. Prepara los servicios locales, abre el Pixel 6 virtual `DeclaraUCR_API36` (Android 16 / API 36), compila, instala y abre la aplicación. La primera preparación puede tardar por las descargas del SDK. La APK entregada está en `output/android/DeclaraUCR-local-debug.apk`.

**Web:**

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

En web, al recargar o cerrar la pestaña se vuelve a pedir el inicio de sesión. Android conserva su sesión nativa. Las cuentas y los documentos se conservan en los servicios locales.

## Qué hace

- Registro, inicio de sesión, recuperación de contraseña y edición del perfil.
- Nombramientos UCR y trabajos en otras instituciones; fechas, jornada y bloques de lunes a sábado.
- Cargos y fracciones de jornada UCR; detalle de actividades y cursos cuando corresponde.
- Validación de traslapes, horas esperadas, exclusión de 12:00–13:00 y máximo diario de diez horas.
- Borradores, validación, firmas internas, revisión del superior, devoluciones, versiones y trámite en RRHH.
- Historial de movimientos, observaciones, notificaciones y generación/archivo de PDF.
- Administración de roles y períodos académicos.
- Edición móvil en cuatro pasos: Datos, Nombramientos, Horarios y Resumen, con guardado en cualquier paso y aviso de cambios al salir.
- Observaciones adicionales independientes del resumen automático, duraciones de intervalos y enlaces para corregir los errores.

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

En **Terminal → Ejecutar tarea** están disponibles los accesos para iniciar Android o web, detener y comprobar el entorno local. Para depurar Android, seleccioná **DeclaraUCR Android local** en Ejecutar y depurar y presioná F5; requiere la extensión Flutter de VS Code. Los comandos de Flutter deben ejecutarse desde la carpeta que contiene `pubspec.yaml`.

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
node scripts/check-drafts.cjs
# Emulador encendido: recorrido instrumentado y evidencias
powershell -ExecutionPolicy Bypass -File Run-Android-Evidence.ps1
```

Pasaron **110 pruebas Flutter**, **67 pruebas del validador del servidor**, **13 casos de borradores y permisos** y **12 comprobaciones del flujo local**. Se añadieron pruebas instrumentadas en Android para el ciclo de los cuatro roles y para recuperar y completar un borrador después de cerrar el proceso. Los resultados y las capturas están en [evidence/android](evidence/android/). Las pruebas de adaptación cubren 320, 360 y 600 dp con texto normal y al 200 %, incluido el teclado. El PDF de evidencia fue generado por la aplicación Android y tiene dos páginas.

Las comprobaciones integrales crean documentos ficticios adicionales. Después de ejecutar `flutter drive`, el archivo temporal `build/app/outputs/flutter-apk/app-debug.apk` contiene la entrada de pruebas. Ejecutá el inicio Android normal para volver a compilar e instalar la aplicación de uso habitual.

## Persistencia y compatibilidad

`saveDeclarationDraft` admite campos vacíos y conflictos en `BORRADOR`, comprueba propietario, rol, versión, tipos y límites, y escribe documento, versión e historial en una transacción. El editor reserva el identificador antes del primer guardado; repetir la misma operación devuelve el mismo documento y `saved: false` cuando no hubo cambios. La confirmación de guardado requiere los servicios de esta PC encendidos.

Validar vuelve a comprobar en el servidor los datos obligatorios, cédula del perfil, período habilitado, superior y horarios. Las versiones firmadas conservan sus restricciones e historial. `additionalObservations` admite hasta 2000 caracteres; documentos anteriores se leen con texto vacío y los clientes antiguos que omitan ese campo conservan el valor existente. `observations` sigue siendo el resumen automático.

## Reflexión técnica del laboratorio

1. **¿Qué se reutilizó del sistema web?** Los modelos `Declaration`, `Appointment` y `TimeBlock`, autenticación Firebase, `DeclarationService`, perfiles, selector de superior, validación de jornadas, historial, notificaciones, PDF y las funciones con transacciones. Android utiliza el mismo backend y códigos de estado.
2. **¿Qué dificultades tuvo la adaptación?** El formulario original era demasiado extenso, las tablas no cabían y los controles con texto ampliado se desbordaban. Se dividió la edición en cuatro pasos, se usaron tarjetas y listas desplazables, y se ajustaron los botones y encabezados con pruebas de 320–600 dp. El emulador necesita `10.0.2.2` para llegar a la PC.
3. **¿Cómo ayudó el manual UCR?** Dio una paleta, tipografía e identificadores comunes. `UcrColors` y `UcrTheme` centralizan la apariencia; Myriad Pro, la firma oficial y la firma promocional conservan sus proporciones. Se eligieron combinaciones de texto legibles siguiendo también la guía institucional de contraste.
4. **¿Qué faltaría para el flujo completo?** El alcance acordado ya incluye firmas internas, devolución, versiones y RRHH mediante las funciones existentes, con pruebas de los cuatro roles. Para una operación institucional real se necesitarían configuración y revisión de producción, políticas de respaldo y auditoría y, si se exige, integración con un proveedor de firma digital certificada. El registro interno actual no equivale a esa firma.

## Firebase de Internet

La configuración original está en `lib/firebase_options.dart` y `firebase.json`. Ejecutar Flutter sin `USE_FIREBASE_EMULATORS=true` conecta esa configuración. Los accesos de inicio local siempre habilitan explícitamente los emuladores.

No se desplegaron cambios en Internet. Android se entrega como APK de desarrollo local. No incluye iOS ni firma digital certificada. El PDF fue revisado visualmente; esto no representa una certificación institucional ni una auditoría completa de seguridad.
