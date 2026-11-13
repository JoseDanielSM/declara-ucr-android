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

Adaptación del proyecto [Greyyss/horario_ucr](https://github.com/Greyyss/horario_ucr). Las firmas de declaraciones son registros internos; no son firmas digitales certificadas. Los recursos institucionales y sus fuentes están documentados en la matriz del laboratorio.
