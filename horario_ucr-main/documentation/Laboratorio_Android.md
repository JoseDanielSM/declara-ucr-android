# Laboratorio Android — DeclaraUCR

## Alcance y ejecución

El PDF del laboratorio exige un módulo móvil de captura, validación, borradores y resumen. El plan aprobado amplía ese alcance para conservar los cuatro roles, las firmas electrónicas internas, versiones, RRHH, administración, notificaciones y PDF que ya existían. Los datos utilizados en las pruebas son ficticios.

Desde Windows: `Iniciar-DeclaraUCR-Android.cmd`. Desde VS Code: tarea **DeclaraUCR: iniciar Android**, o configuración **DeclaraUCR Android local** con F5. La carpeta de comandos Flutter es la que contiene `pubspec.yaml`, dentro de la carpeta exterior abierta en VS Code.

Herramientas comprobadas en esta PC: Flutter 3.47.9 / Dart 3.13.7, Node 24.19, Firebase CLI 15.34, Java 21 para Firebase y herramientas AVD, JBR de Android Studio para Gradle, SDK Android API 36 y AVD Pixel 6 x86_64 con aceleración WHPX. La primera descarga de la imagen es de aproximadamente 1.8 GB y requiere varios GB disponibles para extraerla. Las evidencias de esta guía se obtuvieron con una APK de desarrollo y Firebase local. La distribución posterior para teléfono es un APK release conectado al Firebase original; consultá [Instalación Android](Instalacion_Android.md) y [Estado de entrega](Estado_entrega.md) para distinguir ambos entornos.

| Servicio | Puerto de la PC |
| --- | --- |
| Web local | 7357 |
| Firebase Authentication | 9099 |
| Firestore | 8180 |
| Functions, región `us-east1` | 5001 |
| Storage | 9199 |
| Notificaciones WebSocket | 8080 |
| Consola Firebase local | 4000 |

El proyecto ficticio es `demo-declaraucr-local`. Web se conecta a `127.0.0.1`; Android Emulator a `10.0.2.2`, la dirección de la PC desde ese dispositivo virtual. Las conexiones sin cifrar se permiten únicamente en el manifiesto Android de depuración. La persistencia temporal de sesión de Firebase Web se aplica solamente en web. Android utiliza la sesión nativa.

Las cuentas son `declarante@local.test`, `superior@local.test`, `rrhh@local.test` y `admin@local.test`, con contraseña común `PruebaUCR2026!`. Al terminar, `Detener-DeclaraUCR.cmd` exporta los datos antes de apagar Firebase y las notificaciones; después se puede cerrar el teléfono virtual. No es un modo de trabajo sin conexión: la confirmación del guardado depende de estos servicios.

## Arquitectura y componentes reutilizados

| Componente | Implementación |
| --- | --- |
| Arranque y autenticación | `lib/main.dart`, `lib/services/local_environment.dart`; misma autenticación para web y Android |
| Navegación por rol | `lib/pages/dashboard.dart`; navegación inferior móvil y menú lateral |
| Datos y persistencia | Modelos existentes y `DeclarationService`; nuevo resultado `SaveResult(id, version, saved)` |
| Editor móvil | `lib/pages/declaration_editor.dart`; cuatro pasos con estado en memoria y salida protegida |
| Nombramientos y bloques | `AppointmentPage` existente, ahora admite guardar contenido incompleto; catálogo UCR y puesto externo libre |
| Validación | `ValidationService` existente ampliado con `ValidationIssue`, ubicación y bloques del conflicto |
| Servidor | `functions/declaration-handlers.js`, callable `saveDeclarationDraft`, normalizador `draft-validation.js` |
| Firmas e historial | Máquina de estados, transacciones y versiones existentes; no se simulan firmas mediante un cambio visual |
| PDF y notificaciones | Servicios Flutter y funciones de archivo, descarga y WebSocket existentes |
| Identidad visual | `UcrColors`, `UcrTheme`, Myriad Pro y recursos oficiales |

El editor asigna un ID antes del primer guardado y conserva el contenido al cambiar de paso. El guardado reserva la misma referencia y transacción para declaración, versión e historial. Un reintento idéntico no añade otro documento ni evento. Un número de versión desactualizado se rechaza. La comparación de cédula con el perfil y los permisos se aplican en el servidor.

Los borradores aceptan valores vacíos compatibles con los modelos existentes y conflictos de horarios. La estructura sigue limitada: como máximo 40 nombramientos por lista, 72 bloques por nombramiento, texto limitado por campo y carga total de 500 KB. Los tipos incorrectos se rechazan. Antes de `VALIDADA` se comprueban otra vez todos los requisitos de contenido, período, superior y horario. Los estados y versiones posteriores conservan las restricciones originales.

`observations` es el resumen automático. `additionalObservations` es el texto opcional del declarante, de hasta 2000 caracteres, y se conserva en documento y versión y se muestra en edición, consulta y PDF. La lectura de documentos antiguos usa `''`; una escritura del cliente antiguo que omita el campo conserva el valor guardado. No se modifican versiones ya firmadas.

## Matriz de cumplimiento

| Requisito | Resultado y evidencia |
| --- | --- |
| R1: inicio, listado, estados y acceso a borradores | Inicio y Trámites con tarjetas; `01-inicio-android.png` y reapertura instrumentada |
| R2: información personal, laboral, vigencia e instituciones | Datos del perfil, selector de período/superior, catálogo UCR, puesto externo libre y observaciones adicionales |
| R3: lunes a sábado, intervalos y duración | Paso Horarios y resumen; duración por intervalo, horas UCR y externas; `02-horarios-conflicto.png` |
| R4: fin posterior y traslapes entre instituciones | Validación Flutter y servidor, problemas con día y bloques y acceso a corrección; caso obligatorio incluido |
| R5: persistencia reutilizada y recuperación | Transacción de Firebase local, ID estable, reintento sin duplicados y prueba después de cerrar el proceso Android |
| R6: resumen y regreso a edición | Datos, nombramientos, horarios, totales, problemas y estado; `03-resumen-corregido.png`, `07-borrador-recuperado.png`, `08-borrador-completado-validado.png` |
| Identidad y accesibilidad | Tema compartido, recursos oficiales sin deformación, texto base 16, controles de 48 dp y pruebas de texto al 200 % |
| Extensión: cuatro roles | Recorrido de firmas internas, devolución y versión 2, aprobación, recepción y finalización; capturas 04–06 |
| Extensión: PDF | `declaracion-android.pdf`, dos páginas, generado en Android y archivado y descargado con comprobación de contenido |
| Código, evidencias y entrega | Repositorio Git, APK local, capturas reales, video y documentación |

## Pruebas y reproducción

```powershell
flutter analyze --no-pub
flutter test --no-pub
node --test security_tests/backend_validator.test.cjs
# Servicios locales encendidos:
node scripts/check-local.cjs
node scripts/check-drafts.cjs
powershell -ExecutionPolicy Bypass -File Run-Android-Evidence.ps1
```

El caso obligatorio registra lunes 08:00–12:00 y 11:00–14:00: identifica exactamente el traslape 11:00–12:00 y rechaza validar. Además informa la invasión del almuerzo y la diferencia de jornada. Al cambiar el segundo bloque a 13:00–14:00, acepta las cinco horas UCR de una fracción 1/8. Se mantienen las reglas de almuerzo y máximo diario de diez horas. Los casos existentes también cubren instituciones distintas, intervalos contiguos, fin anterior al inicio, fechas inexistentes y valores numéricos inválidos.

Las pruebas de borradores cubren ausencia de datos, reintentos, propietario y rol incorrectos, versiones antiguas, campos no admitidos, límites, observaciones, metadatos editables, puestos externos libres y prohibición de modificar contenido validado. La ejecución original registrada en las evidencias aprobó 110 pruebas Flutter e incluye las combinaciones de 320, 360 y 600 dp, texto 100/200 % y teclado para acceso y panel de validación. La revisión posterior aprobó 114 pruebas, con cuatro casos adicionales de filtros y tarjetas interactivas. No se altera el manifiesto histórico para atribuirle pruebas posteriores.

`integration_test/mobile_workflow_test.dart` ejecuta servicios reales desde Android: guarda un formulario incompleto desde su botón, impide validar el conflicto, corrige cinco horas, valida, firma internamente, devuelve, crea versión 2, vuelve a firmar, recibe y finaliza en RRHH, archiva y descarga el PDF. Accede a los cuatro roles y captura sus pantallas. Las transiciones se invocan mediante el mismo servicio Flutter que usan los botones; no es una prueba exhaustiva de cada toque de todos los diálogos.

`integration_test/restart_test.dart` se ejecuta en otro proceso después de `adb shell am force-stop cr.ac.ucr.declaraucr`. Recibe el ID del borrador incompleto de la prueba anterior, verifica sus datos, abre el editor, prueba sus anchos y texto ampliado con teclado real, lo completa, repite el guardado con el mismo ID y finalmente valida. Para repetirlo, usá el `partialDraftId` recién creado por el recorrido:

```powershell
$report = Get-Content evidence/android/integration-results.json -Raw | ConvertFrom-Json
$env:ANDROID_REPORT_NAME = 'restart-results'
adb -s emulator-5554 shell am force-stop cr.ac.ucr.declaraucr
flutter drive --no-pub --disable-dds --host-vmservice-port=53103 --driver=test_driver/integration_driver.dart --target=integration_test/restart_test.dart -d emulator-5554 --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2 --dart-define=NOTIFICATIONS_WS_URL=ws://10.0.2.2:8080 "--dart-define=CHECK_DRAFT_ID=$($report.partialDraftId)"
Remove-Item Env:ANDROID_REPORT_NAME
```

Resultados estructurados: `evidence/android/integration-results.json`, `restart-results.json` y `build-manifest.json`. Los registros detallados de ejecución y comprobaciones del servidor permanecen en `.local/`, fuera de Git. Para repetir la prueba de reapertura hace falta un borrador todavía incompleto; al finalizarla queda `VALIDADA`.

## Evidencias

Las capturas y el video corresponden a la aplicación real en el Pixel 6 API 36. El video muestra el inicio, guardado, conflicto y corrección y el recorrido de roles; no tiene narración. El PDF de dos páginas incluye el horario corregido, ambas observaciones, nombres y fechas del registro de firmas internas, y el aviso de que no equivale a una firma digital certificada. Se revisaron ambas páginas renderizadas y las capturas.

La APK normal se recompila con entrada `lib/main.dart` después de las pruebas instrumentadas y se copia a `output/android/DeclaraUCR-local-debug.apk`. Ese directorio y las APK no se incluyen en el commit. El repositorio conserva el estado previo en el commit `43f8561` y la implementación en un commit final identificable.

## Justificación visual y fuentes

Se consultó el [Manual de Identidad Visual UCR, 2019](https://psico.ucr.ac.cr/images/recursos/2019_manual-identidad-visual-web.pdf), páginas **24–31 y 122–123**, más las páginas 33–34 sobre firmas:

- Página 24: Myriad Pro es una familia institucional legible; se reutiliza el archivo de fuente existente, incluido en la aplicación, sin depender de descargas al iniciar.
- Páginas 28–31: predominan azul `#005DA4`, celeste `#00C0F3` y blanco; amarillo `#FFE06A` y verde `#6DC067` quedan como acentos. Los códigos se centralizan y los estados incluyen texto e iconos.
- Páginas 33–34: se usan identificadores oficiales completos, escalados con la proporción original, sin dibujar escudos ni sustituir sus letras. La firma oficial horizontal procede del [sitio principal UCR](https://www.ucr.ac.cr/vistas/webucr_ucr_7/imagenes/firma-ucr-c.svg). Se conservan SVG original y PNG de representación.
- Páginas 122–123: navegación y controles Material de Android, icono propio de documento con versión monocromática, apariencia limpia y firma institucional en la parte superior. La firma promocional con texto de la pantalla de carga se extrajo íntegra de la lámina oficial de la página 34, incluyendo su fondo celeste; conserva la disposición y proporciones del recurso original. El recurso promocional sin texto también procede de [UCR](https://www.ucr.ac.cr/medios/imagenes/2016/ucr.svg).

La [guía institucional de paleta accesible, 2025](https://ci.ucr.ac.cr/sites/default/files/2025-10/Analisis%20de%20color%20paleta%20UCR%20accesible.pdf), páginas **3–8**, complementa el manual: textos oscuros sobre fondos claros, blanco sobre azul para acciones, colores claros como superficies y acentos y texto base de 16. Se evita texto blanco pequeño sobre celeste, amarillo o verde claro. Los botones compartidos tienen al menos 48 dp de altura; los errores tienen texto específico, no dependen únicamente del color y enlazan a la edición. Estas decisiones y pruebas de adaptación no equivalen a una auditoría completa de accesibilidad.

## Dificultades y decisiones

El formulario web era largo y sus filas y tablas no se acomodaban al teléfono. Se conservaron los servicios y se separó la edición móvil en cuatro pasos, con listas y tarjetas desplazables y botones que se acomodan con texto ampliado. Se conservaron los datos al navegar y se protegió la salida cuando hay cambios.

El guardado anterior exigía una declaración completa; se añadió un camino de borrador con estructura limitada, manteniendo estricta la validación de estado posterior. Fue necesario preservar las observaciones adicionales cuando escribe un cliente antiguo y mantener versiones firmadas inmutables.

La herramienta nueva de Android SDK usa rutas de paquete con `/` en su comando `android sdk install`; el creador de AVD conserva el formato con `;`. La conexión de depuración automática tuvo un bloqueo de DDS en esta PC; las pruebas instrumentadas usan `--disable-dds` y un puerto explícito. Algunos plugins Firebase emiten una advertencia de compatibilidad futura con Kotlin integrado de Gradle; con las versiones verificadas las compilaciones terminan correctamente.

Las evidencias de esta guía corresponden al entorno local. Posteriormente se registró Android en el Firebase original y se publicaron únicamente las cuatro funciones móviles descritas en [Estado de entrega](Estado_entrega.md), con la cuenta autorizada. El APK para teléfono usa ese Firebase por Internet y no necesita la PC encendida. No se configuró iOS ni se emitieron firmas digitales certificadas.

## Correspondencia de las pruebas y entregables del PDF

| Sección del PDF | Evidencia disponible y alcance |
| --- | --- |
| 7, prueba 01: declaración válida | El recorrido Android guarda el borrador corregido, abre el resumen y valida las cinco horas UCR; captura `03-resumen-corregido.png` |
| 7, prueba 02: horarios traslapados | Lunes 08:00–12:00 y 11:00–14:00: conflicto 11:00–12:00, validación rechazada y estado BORRADOR; captura `02-horarios-conflicto.png` |
| 7, prueba 03: datos incompletos | Guardado de borrador incompleto y errores visibles de período/superior; `restart-results.json`, `requiredFieldErrorsVisible: true` |
| 7, prueba 04: persistencia | Cierre del proceso, reapertura y recuperación del ID y contenido; `restart-results.json`, `restoredAfterProcessStop: true` |
| 7, prueba 05: vista móvil | Recorrido en Pixel 6/API 36 y casos 320/360/600 dp, texto normal/ampliado y teclado; capturas y resultados de reapertura |
| 8: código y commit | Repositorio Git e historial; referencia previa `43f8561`, implementación inicial Android `258474c` y cambios posteriores identificables |
| 8: tres capturas mínimas | `01-inicio-android.png`, `02-horarios-conflicto.png` y `03-resumen-corregido.png`; se incluyen seis capturas adicionales |
| 8: video de hasta dos minutos | `demostracion-android.mp4`, duración registrada de 63,1 segundos |
| 8: README técnico | [README principal](../../README.md) y [README técnico](../README.md): estructura, reutilización, persistencia, pruebas y dificultades |
| 8: justificación visual | Fuentes, decisiones y páginas consultadas en la sección anterior de esta guía |
| 10: cuatro preguntas de reflexión | Preguntas completas y respuestas explícitas en ambos README |

Todas las pruebas del laboratorio conservadas aquí usan datos ficticios. El PDF admite emulador o teléfono: una comprobación pendiente en teléfono físico no invalida la evidencia del emulador, pero no debe presentarse como ya realizada. La rúbrica y la valoración institucional corresponden al docente; las verificaciones documentadas no equivalen a una auditoría completa de accesibilidad.
