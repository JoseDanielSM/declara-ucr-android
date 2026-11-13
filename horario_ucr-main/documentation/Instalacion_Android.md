# DeclaraUCR: instalación y operación en Android

## Aplicación

DeclaraUCR adapta el sistema existente de declaraciones juradas de horario y jornada laboral a Android. Reutiliza sus modelos Flutter, autenticación, permisos y flujo de revisión. El editor móvil contiene Datos, Nombramientos, Horarios y Resumen; permite conservar borradores incompletos y exige corregir los errores antes de validar. El caso del laboratorio detecta el traslape del lunes 11:00–12:00 y acepta cinco horas UCR al corregir el segundo intervalo a 13:00–14:00.

## Instalar el APK

1. Copiá `DeclaraUCR-telefono.apk`, disponible en `output/android/` del proyecto, a tu teléfono.
2. Abrí el archivo y autorizá la instalación desde la aplicación que lo abrió cuando Android lo solicite.
3. Iniciá DeclaraUCR con Internet e ingresá con una cuenta del proyecto **DeclaraHorario-UCR**.

La compilación release contiene las arquitecturas Android que genera Flutter para dispositivos físicos y emulador; el requisito mínimo efectivo es Android 7 o superior, según las dependencias fijadas. El APK no necesita que esta PC esté encendida. Las cuentas `@local.test` pertenecen únicamente al entorno de laboratorio de la PC y no se crean en el Firebase real.

Si el dispositivo tiene una compilación de desarrollo con el mismo identificador y una firma distinta, Android rechazará la actualización. Conservá antes cualquier avance que no hayas guardado y desinstalá esa compilación de prueba para instalar la versión release. Para actualizar versiones release posteriores se debe conservar la misma clave y aumentar `version` en `pubspec.yaml`.

## Firebase original

| Propiedad | Valor |
| --- | --- |
| Proyecto | `declarahorario-ucr-cff7a` — DeclaraHorario-UCR |
| Aplicación Android | `cr.ac.ucr.declaraucr` |
| ID Firebase Android | `1:807844528626:android:91e2b604b8269a565a2b6b` |
| Región de funciones | `us-east1` |
| Archivo de cliente | `android/app/google-services.json` y `lib/firebase_options.dart` |

La configuración de cliente Firebase identifica el proyecto; no concede permisos de administración. Las cuentas de servicio, sesiones de Firebase CLI y claves privadas de firma no forman parte del código publicado.

Se conservan las funciones originales del proyecto. El módulo móvil añade únicamente:

| Función | Responsabilidad |
| --- | --- |
| `saveDeclarationDraft` | Guarda datos incompletos con ID estable; comprueba usuario, rol, versión, tipos y límites; actualiza documento, versión e historial en una transacción |
| `validateMobileDeclaration` | Comprueba datos completos, perfil, período, superior y horarios antes de validar |
| `newMobileDeclarationVersion` | Crea la versión de corrección sin modificar la versión firmada anterior |
| `markMobileNotificationsRead` | Modifica exclusivamente la bandeja del usuario autenticado |

Las notificaciones del APK se consultan directamente desde Firestore; ya no necesitan un servidor WebSocket en la PC. Son notificaciones dentro de la aplicación, no avisos push con la aplicación cerrada. El entorno local conserva el WebSocket para sus pruebas. La generación y descarga del PDF reutiliza las funciones originales de archivo.

El estado verificado de la publicación se registra en `Estado_entrega.md`. Una función desplegada pero sin permiso de invocación de Cloud Run no puede utilizarse desde el cliente. Su acceso de red debe permitir llamar al endpoint, mientras el código exige una sesión Firebase y valida los permisos de cada operación. No se deben quitar las comprobaciones de autenticación para resolver un fallo de infraestructura.

## Compilar en otra PC

Instalá Flutter 3.47.9 de referencia, Android Studio con SDK y herramientas Android, JDK 21 o superior y Node 24 para las herramientas del backend. Consultá `Instalacion_en_otra_PC.md` para la preparación de Windows y las licencias Android.

Desde la carpeta exterior del repositorio:

```powershell
.\Preparar-DeclaraUCR.cmd
.\Compilar-APK.cmd
```

`Build-Phone.ps1` genera o reutiliza una clave release privada, configura la firma y ejecuta:

```powershell
flutter build apk --release --target=lib/main.dart --dart-define=USE_FIREBASE_EMULATORS=false
```

El resultado se copia a `horario_ucr-main/output/android/DeclaraUCR-telefono.apk`. Conservá **juntos** `.local/signing/declaraucr-release.jks` y `android/key.properties` en un respaldo privado: son necesarios para seguir publicando actualizaciones instalables sobre la misma aplicación. No los subas a Git. En otra PC restaurá ambos y ajustá `storeFile` en `key.properties` a la ubicación del archivo JKS. Crear una clave nueva produce otra firma.

## Desarrollo y pruebas

```powershell
# Dentro de horario_ucr-main/
flutter analyze --no-pub
flutter test --no-pub
npm.cmd run test:backend
```

Los 110 casos Flutter cubren horarios, formulario y adaptación de 320, 360 y 600 dp con texto normal/ampliado y teclado. Las 67 pruebas del validador y los casos de servicios locales se describen en `Laboratorio_Android.md`. Las capturas y el PDF de `evidence/android/` se obtuvieron con datos ficticios en emuladores y no certifican que se hayan ejecutado todos los roles con cuentas reales en producción.

La edición, resumen y PDF muestran observaciones automáticas y adicionales por separado. Las firmas de declaración son registros electrónicos internos; la firma criptográfica del APK sirve para distribuir y actualizar la aplicación y no convierte esas declaraciones en documentos con firma digital certificada.

## Operación

Para usar el teléfono normalmente no ejecutes los accesos `Iniciar-DeclaraUCR*`, que preparan la demostración local. El registro y la asignación de roles dependen de los permisos del Firebase original. Los borradores confirmados se guardan en Firebase; guardar requiere conexión. El período y el superior deben estar habilitados y disponibles.

Los despliegues requieren una cuenta autorizada del proyecto. El alcance móvil se publica con `firebase deploy --project declarahorario-ucr-cff7a --only functions:saveDeclarationDraft,functions:validateMobileDeclaration,functions:newMobileDeclarationVersion,functions:markMobileNotificationsRead`. Esta selección evita reemplazar o eliminar funciones ajenas al módulo móvil. No se publica Hosting automáticamente ni se sustituyen las reglas del proyecto por las del emulador.

Referencias técnicas: [Firebase para Flutter](https://firebase.google.com/docs/flutter/setup), [compilación y firma Android](https://docs.flutter.dev/deployment/android). La matriz del laboratorio y las fuentes de identidad visual se conservan en `Laboratorio_Android.md`.
