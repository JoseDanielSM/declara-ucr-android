# DeclaraUCR

Aplicación académica Flutter para Android y web que adapta el sistema existente de declaraciones juradas de horario y jornada laboral de la UCR. Incluye cuatro roles, edición en pasos, borradores, validación de horarios, firmas electrónicas internas, seguimiento, notificaciones y PDF.

## Instalar en el teléfono

El APK firmado se genera en `horario_ucr-main/output/android/DeclaraUCR-telefono.apk`. Copialo al teléfono, abrilo e ingresá con una cuenta del Firebase original **DeclaraHorario-UCR**. El teléfono necesita Internet; no necesita que la PC esté encendida. Las cuentas locales de prueba no pertenecen al Firebase real.

**Estado de la integración:** consultá [Estado de entrega](horario_ucr-main/documentation/Estado_entrega.md). El APK compila, pero la invocación de las funciones móviles nuevas requiere completar permisos de Firebase antes de considerar operativo el guardado en producción.

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

Adaptación del proyecto [Greyyss/horario_ucr](https://github.com/Greyyss/horario_ucr). Las firmas de declaraciones son registros internos; no son firmas digitales certificadas. Los recursos institucionales y sus fuentes están documentados en la matriz del laboratorio.
