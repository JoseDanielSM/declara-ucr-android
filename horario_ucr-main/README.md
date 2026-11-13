# DeclaraUCR — README técnico

## Integrantes

Integrantes ordenados alfabéticamente por primer apellido:

| Nombre completo | Carné |
| --- | --- |
| Daniel Araya Hernandez | C4C543 |
| Luis Gomez Esquivel | C4F464 |
| Eidan Picado Leiva | C4I410 |
| José Segura Menjivar | C4J929 |
| Grace Solano Delgado | C4K066 |

## Contenido

- [Descripción](#descripción)
- [Instalación y compilación](#instalación-y-compilación)
- [Arquitectura](#arquitectura)
- [Panel interactivo](#panel-interactivo)
- [Pruebas](#pruebas)
- [Reflexión técnica de cierre](#reflexión-técnica-de-cierre)

## Descripción

Cliente Flutter Android/web del sistema de declaraciones juradas de horario y jornada laboral UCR. Captura datos personales y laborales, nombramientos UCR y externos, bloques de lunes a sábado y observaciones; guarda borradores incompletos y comprueba los datos antes de validarlos. Reutiliza el flujo existente de declarante, superior, Recursos Humanos y administración.

## Instalación y compilación

Para instalar el APK y recompilar con firma release, seguí [Instalación Android](documentation/Instalacion_Android.md). Para preparar el SDK y la demostración local en otra PC, usá [Preparación de otra PC](documentation/Instalacion_en_otra_PC.md).

```powershell
# Desde la carpeta exterior del repositorio:
.\Preparar-DeclaraUCR.cmd
.\Compilar-APK.cmd
```

El APK real usa `declarahorario-ucr-cff7a`. El entorno local usa `demo-declaraucr-local` con parámetros explícitos y no requiere permisos del proyecto real. Las claves de firma y contraseñas de distribución se conservan fuera de Git. El estado del despliegue se detalla en [Estado de entrega](documentation/Estado_entrega.md).

## Arquitectura

| Componente | Ubicación y responsabilidad |
| --- | --- |
| Arranque y Firebase | `lib/main.dart`, `lib/firebase_options.dart`, `lib/services/local_environment.dart` |
| Modelos | `lib/models/declaration.dart`: declaración, nombramiento y bloque horario |
| Edición móvil | `lib/pages/declaration_editor.dart`: Datos, Nombramientos, Horarios y Resumen |
| Roles y seguimiento | `lib/pages/dashboard.dart`, `declaration_views.dart`, `admin_page.dart` |
| Persistencia | `lib/services/declaration_service.dart`, transacciones del servidor en `functions/declaration-handlers.js` |
| Validación | `validation_service.dart`, `personal_data_validator.dart`, `functions/schedule-validation.js` |
| Notificaciones | Firestore y callable autenticado en Firebase real; WebSocket para demostración local |
| PDF | Servicios y diseño PDF existentes, archivo/descarga en las funciones originales |
| Tema institucional | `lib/theme/`, Myriad Pro y recursos oficiales con proporciones conservadas |

El editor reserva un ID antes del primer guardado. `SaveResult` devuelve ID, versión y si se guardaron cambios. El servidor comprueba identidad, rol, versión, tipos y límites y guarda declaración, versión e historial conjuntamente. Un reintento idéntico no duplica el documento.

`BORRADOR` permite datos pendientes y conflictos. Validar exige perfil coherente, período habilitado, superior válido, vigencias, jornada y horarios completos. Los problemas indican el día y bloques afectados y permiten regresar a corregir. Se mantienen almuerzo y máximo diario de diez horas. Los puestos externos aceptan texto libre.

`observations` contiene el resumen automático; `additionalObservations` conserva el texto opcional del declarante, hasta 2000 caracteres. Ambos se muestran en consulta y PDF. Los documentos anteriores se leen con texto adicional vacío y las versiones firmadas permanecen inmutables.

## Panel interactivo

Las tarjetas de Inicio y Trámites abren la lista de declaraciones y aplican el filtro elegido. Limpian la búsqueda anterior, muestran la selección y llevan al listado. Un contador en cero mantiene el filtro y muestra el resultado vacío.

| Tarjeta | Resultado |
| --- | --- |
| Total de declaraciones | Todas las declaraciones visibles para el rol actual |
| Pendientes | Estados distintos de `FINALIZADA` y `ANULADA`, incluidos borradores |
| Finalizadas | Solo `FINALIZADA` |
| Borrador | Solo `BORRADOR` |

Las tarjetas admiten pulsación, navegación por teclado y lectores de pantalla; su altura se adapta al texto ampliado. Los filtros conservan los permisos y el alcance de consulta del usuario.

## Pruebas

Desde esta carpeta:

```powershell
flutter analyze --no-pub
flutter test --no-pub
npm.cmd run test:backend
# Solo con los emuladores locales encendidos:
npm.cmd run test:local
npm.cmd run test:drafts
```

La batería Flutter incluye 114 pruebas, el validador 67 y los servicios locales 25 comprobaciones. Las cuatro pruebas nuevas verifican filtros y tarjetas a 320, 360 y 600 dp con texto al 200 %, teclado y acciones accesibles. El caso obligatorio informa lunes 11:00–12:00 como traslape entre 08:00–12:00 y 11:00–14:00; al corregir a 13:00–14:00 acepta cinco horas UCR. Las evidencias previas también comprueban recuperación de borrador, versión de devolución, firmas internas y RRHH en emuladores. No se presentan como pruebas ejecutadas con cuentas reales en producción.

## Reflexión técnica de cierre

Las cuatro preguntas corresponden a la sección 10 del PDF (página 5). También están respondidas en el [README principal del repositorio](../README.md#reflexión-técnica-de-cierre).

### 1. ¿Qué componentes del sistema web se pudieron reutilizar en la aplicación móvil?

Los modelos de declaración, nombramiento e intervalo; Firebase Authentication; perfiles y roles; consultas y servicios de declaración; reglas de validación; historial, versiones y generación de PDF. Se conservó la arquitectura existente y se añadieron adaptación móvil y operaciones de borrador, sin reconstruir la autenticación ni crear un backend independiente.

### 2. ¿Qué dificultades surgieron al adaptar la declaración jurada a una pantalla pequeña?

Las tablas y el formulario extenso dificultaban editar con el teclado abierto. Se dividió la captura en Datos, Nombramientos, Horarios y Resumen, usando tarjetas y contenido desplazable. Se conserva el contenido al avanzar o regresar, se avisa al salir con cambios y los conflictos enlazan al día y bloques que requieren corrección. Se verificaron 320, 360 y 600 dp con texto ampliado.

### 3. ¿Cómo contribuyó el Manual de Identidad Visual de la UCR a estandarizar la experiencia?

Unificó paleta, Myriad Pro, jerarquía y tratamiento de identificadores oficiales sin deformarlos. El tema Flutter comparte esas decisiones entre pantallas y plataformas; la guía de contraste complementó la selección de texto y fondos. Estados y errores incluyen texto e iconos. Las páginas consultadas y recursos están identificados en [la justificación visual](documentation/Laboratorio_Android.md#justificación-visual-y-fuentes).

### 4. ¿Qué cambios se requerirían para integrarse con el flujo completo de firmas y aprobación?

Se requieren permisos por rol en servidor, transiciones de estado verificadas, firmas ligadas a una versión, historial de autor y fecha, devolución con nueva versión, notificaciones y recepción por RRHH. Esta adaptación conserva esos mecanismos existentes como ampliación del mínimo del laboratorio. Las firmas son registros electrónicos internos identificados como tales; una firma digital certificada requeriría un proveedor y validación de certificados y documentos. Firmar el APK no certifica las declaraciones.
