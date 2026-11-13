# DeclaraUCR

Aplicación académica Flutter para Android y web que adapta el sistema existente de declaraciones juradas de horario y jornada laboral de la UCR. Incluye cuatro roles, edición en pasos, borradores, validación de horarios, firmas electrónicas internas, seguimiento, notificaciones y PDF.

## Integrantes

Integrantes ordenados alfabéticamente por primer apellido:

| Nombre completo | Carné |
| --- | --- |
| Daniel Araya Hernandez | C4C543 |
| Luis Gomez Esquivel | C4F464 |
| Eidan Picado Leiva | C4I410 |
| José Segura Menjivar | C4J929 |
| Grace Solano Delgado | C4K066 |
| Cristian Chinchilla Fonseca | C4E360 |

## Instalar en el teléfono

El APK firmado se genera en `horario_ucr-main/output/android/DeclaraUCR-telefono.apk`. Copialo al teléfono, abrilo e ingresá con una cuenta del Firebase original **DeclaraHorario-UCR**. El teléfono necesita Internet; no necesita que la PC esté encendida. Las cuentas locales de prueba no pertenecen al Firebase real.

**Versión 1.0.1:** las cuatro funciones móviles están publicadas y su acceso desde el APK está habilitado. Las tarjetas de Total, Pendientes, Finalizadas y Borrador abren los trámites filtrados. Consultá los resultados y límites de verificación en [Estado de entrega](horario_ucr-main/documentation/Estado_entrega.md).

## Documentación

- [Instalación Android, compilación, firma y operación](horario_ucr-main/documentation/Instalacion_Android.md).
- [README técnico](horario_ucr-main/README.md).
- [Matriz del laboratorio, identidad visual y reflexiones](horario_ucr-main/documentation/Laboratorio_Android.md).
- [Preparación de otra PC y entorno local](horario_ucr-main/documentation/Instalacion_en_otra_PC.md).
- [Evidencias del laboratorio con datos ficticios](horario_ucr-main/evidence/android/).

## Compilar

Requiere Flutter, Android SDK y JDK; las versiones de referencia se detallan en la guía. Desde la carpeta exterior:

```powershell
.\Preparar-DeclaraUCR.cmd
.\Compilar-APK.cmd
```

La carpeta `horario_ucr-main/` contiene `pubspec.yaml` y el código de la aplicación. Abrí la carpeta exterior en VS Code para usar las tareas incluidas. Los accesos `Iniciar-DeclaraUCR*` ejecutan la demostración local, separada del APK para teléfono.

## Código y pruebas

Se reutilizan los modelos, servicios, autenticación y flujo del sistema original. Las pruebas Flutter y del validador se ejecutan desde la carpeta de la aplicación. Dependencias, cachés, claves de firma, sesiones, registros y compilaciones se excluyen de Git. Los documentos obsoletos se retiraron del proyecto activo y permanecen en un respaldo privado local y en el historial anterior.

## Estructura y persistencia

| Ubicación | Responsabilidad |
| --- | --- |
| `horario_ucr-main/lib/models/` | Modelos de declaración, nombramientos e intervalos |
| `horario_ucr-main/lib/pages/` | Inicio, Trámites, perfil, editor en cuatro pasos, resumen y vistas por rol |
| `horario_ucr-main/lib/services/` | Autenticación, consultas, guardado, validación y PDF reutilizados |
| `horario_ucr-main/lib/theme/` y `horario_ucr-main/assets/` | Tema, tipografía y recursos institucionales |
| `horario_ucr-main/functions/` | Validaciones y transacciones sobre el Firebase existente |
| `horario_ucr-main/test/`, `security_tests/` e `integration_test/` | Pruebas Flutter, servidor y recorridos Android |

Los borradores usan el mismo Firebase y modelos del sistema original. Se asigna un ID estable antes del primer guardado; una transacción conserva declaración, versión e historial y evita duplicados al reintentar. `BORRADOR` admite información incompleta y conflictos; pasar a `VALIDADA` exige los campos obligatorios y horarios correctos. Las observaciones adicionales se conservan por separado del resumen automático. Recuperar un borrador confirmado requiere conexión al Firebase elegido.

## Verificación del laboratorio y evidencias

| Requisito del PDF | Implementación y comprobación |
| --- | --- |
| R1. Pantalla principal | Identificación del sistema, creación y acceso a declaraciones y borradores en Inicio/Trámites; estados originales conservados |
| R2. Formulario | Datos personales desde el perfil, instituciones, puestos, jornada, vigencia y observaciones; errores de campos pendientes |
| R3. Horario semanal | Bloques de lunes a sábado por nombramiento/institución, duración por intervalo y totales |
| R4. Validación | Fin posterior al inicio, conflictos entre instituciones y acceso para corregir; el caso del lunes detecta el traslape 11:00–12:00 e impide validar |
| R5. Persistencia | Borradores recuperados tras cerrar el proceso Android; mismo ID al reintentar; autenticación y servicios existentes reutilizados |
| R6. Resumen | Datos, nombramientos, horarios, horas, problemas y estado; regreso al apartado que requiere corrección |

Las cinco pruebas de la sección 7 del PDF están cubiertas por los recorridos y resultados conservados: borrador válido/resumen, traslape, campos incompletos, recuperación y vista móvil. La [matriz detallada](horario_ucr-main/documentation/Laboratorio_Android.md) relaciona código, decisiones y evidencias.

- Capturas requeridas: [Inicio](horario_ucr-main/evidence/android/01-inicio-android.png), [registro de horarios](horario_ucr-main/evidence/android/02-horarios-conflicto.png) y [resumen/validación](horario_ucr-main/evidence/android/03-resumen-corregido.png).
- [Video de demostración](horario_ucr-main/evidence/android/demostracion-android.mp4), de 63,1 segundos, dentro del máximo de dos minutos.
- [Recorrido Android](horario_ucr-main/evidence/android/integration-results.json) y [recuperación tras cerrar la aplicación](horario_ucr-main/evidence/android/restart-results.json), con datos ficticios en Pixel 6/API 36. Las pruebas de adaptación incluyen 320, 360 y 600 dp, texto ampliado y teclado.
- Última comprobación del código: 114 pruebas Flutter y 67 del validador aprobadas, análisis sin problemas y compilaciones Android/web correctas. El [manifiesto original de evidencias](horario_ucr-main/evidence/android/build-manifest.json) conserva los resultados de aquella ejecución; no se reescribe como si fuera una prueba de la versión posterior.

El PDF admite emulador **o** dispositivo Android; las evidencias del emulador satisfacen ese formato de entrega. La comprobación completa con cuentas reales en un teléfono físico sigue pendiente y no se presenta como realizada. La correspondencia de requisitos y las pruebas no sustituyen una evaluación del docente ni una auditoría completa de accesibilidad.

## Identidad visual y dificultades

El tema compartido centraliza azul `#005DA4`, celeste `#00C0F3`, blanco, amarillo `#FFE06A` y verde `#6DC067`. Se emplea Myriad Pro, recursos oficiales con sus proporciones originales y controles adaptados al tacto. La [justificación visual](horario_ucr-main/documentation/Laboratorio_Android.md#justificación-visual-y-fuentes) identifica las fuentes y las páginas 24–31, 33–34 y 122–123 del manual, y las páginas 3–8 de la guía institucional de contraste.

Las principales dificultades fueron adaptar tablas y formularios largos al teléfono, conservar la edición al navegar y con el teclado abierto, y permitir borradores incompletos sin debilitar la validación final. Se resolvieron con tarjetas, edición en pasos, estado conservado, aviso de cambios pendientes y una transacción específica de borrador. También se separaron las conexiones al emulador de las del teléfono y se corrigió el permiso de invocación de las cuatro funciones móviles en Firebase.

## Reflexión técnica de cierre

### 1. ¿Qué componentes del sistema web se pudieron reutilizar en la aplicación móvil?

Se reutilizaron los modelos de declaración, nombramiento e intervalo; Firebase Authentication; perfiles y roles; consultas y servicios de declaración; reglas de validación; historial y versiones; y generación de PDF. Android usa la arquitectura y el Firebase existentes. Se añadieron adaptación móvil y operaciones de borrador, sin reconstruir la autenticación ni crear otro backend independiente.

### 2. ¿Qué dificultades surgieron al adaptar la declaración jurada a una pantalla pequeña?

El formulario extenso y las tablas de la web dificultaban leer y editar con el teclado abierto. Se dividió la captura en Datos, Nombramientos, Horarios y Resumen y se usaron tarjetas y contenido desplazable. Se conservaron los valores al avanzar o retroceder y se probaron 320, 360 y 600 dp con texto ampliado. Los conflictos señalan el día y los bloques y permiten volver a corregirlos.

### 3. ¿Cómo contribuyó el Manual de Identidad Visual de la UCR a estandarizar la experiencia?

Permitió unificar paleta, tipografía Myriad Pro, jerarquía visual y uso de identificadores oficiales sin deformarlos. Las decisiones se centralizaron en el tema Flutter para mantener coherencia entre pantallas y plataformas. La guía institucional de contraste complementó el manual para elegir combinaciones legibles; los estados y errores incluyen texto e iconos, además de color. Las páginas consultadas están en la justificación visual enlazada arriba.

### 4. ¿Qué cambios se requerirían para integrarse con el flujo completo de firmas y aprobación?

Se necesitan autorización por rol en el servidor, transiciones de estado verificadas, firmas asociadas a la versión exacta, historial de quién actúa y cuándo, devolución con nueva versión, notificaciones y recepción por RRHH. Esta adaptación conserva esos mecanismos del sistema existente como ampliación solicitada fuera del mínimo del laboratorio. Las firmas son registros electrónicos internos expresamente identificados; una firma digital certificada exigiría integrar un proveedor y la validación de certificados y documentos. La firma del APK identifica la aplicación, no certifica declaraciones.

Adaptación del proyecto [Greyyss/horario_ucr](https://github.com/Greyyss/horario_ucr). Las firmas de declaraciones son registros internos; no son firmas digitales certificadas. Los recursos institucionales y sus fuentes están documentados en la matriz del laboratorio.
