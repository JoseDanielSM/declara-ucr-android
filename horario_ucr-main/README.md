# DeclaraUCR — README técnico

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

## Reflexión técnica

1. **Reutilización:** modelos, autenticación, perfiles, servicios de declaración, validación, historial, PDF, permisos y transacciones del sistema existente.
2. **Adaptación móvil:** se dividió el formulario en cuatro pasos, se reemplazaron tablas por tarjetas y se probaron 320, 360 y 600 dp con teclado y texto ampliado; se conserva el avance al navegar.
3. **Identidad UCR:** se centralizaron tipografía, colores y componentes; los identificadores oficiales conservan su proporción. Las páginas y fuentes consultadas están en `documentation/Laboratorio_Android.md`.
4. **Flujo completo:** se conservan las firmas electrónicas internas y la revisión existente. Una firma digital certificada requeriría una integración distinta; la firma del APK solo identifica la distribución de la aplicación.
