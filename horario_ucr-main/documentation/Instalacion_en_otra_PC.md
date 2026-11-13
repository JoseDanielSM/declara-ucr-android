# Instalar y ejecutar DeclaraUCR en otra PC

## 1. Qué se instala

El repositorio contiene el código Flutter para Android y web, funciones Firebase, reglas de acceso, servicio de notificaciones, preparación de datos de prueba, accesos de Windows y evidencias. El entorno no necesita Firebase de Internet, una cuenta de Google, una tarjeta ni un despliegue. Los servicios se ejecutan en la PC y el teléfono virtual se conecta a ellos.

Los accesos automáticos soportan **Windows 10/11 x64** con PowerShell 5.1. La configuración Android crea un Pixel 6 x86_64 con Android API 36. Un equipo Windows ARM, Linux o macOS requiere adaptar los accesos y la imagen del emulador; no forma parte de la ruta automática comprobada. La sección 10 describe la ejecución manual del servidor como referencia.

Reservá aproximadamente 20 GB libres para SDK, imagen Android, Gradle, dependencias y compilaciones; es una estimación de preparación, no el tamaño del repositorio. Para Android se recomienda una PC con al menos 16 GB de RAM, virtualización activa y aceleración del emulador. La descarga inicial de la imagen API 36 es de alrededor de 1.8 GB. Para web solamente no se necesita la imagen ni Android Studio.

## 2. Herramientas y versiones

| Herramienta | Versión de referencia | Preparación |
| --- | --- | --- |
| Git para Windows | Versión actual compatible | [Descarga oficial](https://git-scm.com/install/windows); incluí Git Credential Manager |
| Node.js | **24 LTS**; comprobado con 24.19.0 y npm 11 | [Descarga oficial](https://nodejs.org/en/download); instalador con PATH y npm |
| Java JDK | **21 recomendado**; el detector admite 21 o superior | [Temurin 21](https://adoptium.net/temurin/releases/?version=21); configurá `JAVA_HOME` y PATH |
| Flutter | **3.47.9 stable**, Dart 3.13.7, usados en la entrega | [Instalación oficial](https://docs.flutter.dev/install) y [archivo de versiones](https://docs.flutter.dev/install/archive) |
| Android Studio y SDK | API 36, Emulator, Platform-Tools, Command-line Tools latest | [Android Studio](https://developer.android.com/studio); solo para Android |
| Navegador | Chrome, Edge o Chromium compatible | Para web; el flujo de escritorio también se comprobó en Brave |
| VS Code | Opcional, con extensiones Dart y Flutter | Abrir la carpeta exterior del repositorio |
| Firebase CLI | **15.34.0**, fijado en el proyecto | Lo instala `Preparar-DeclaraUCR.cmd` mediante `npm ci`; no requiere instalación global ni `firebase login` |

La tabla identifica las versiones comprobadas; una actualización del SDK o de dependencias necesita ejecutar de nuevo las pruebas y compilaciones. Los archivos `pubspec.lock` y los tres `package-lock.json` se incluyen para conservar las dependencias resueltas.

### Flutter y Java

Extraé Flutter en una carpeta de desarrollo donde tu usuario pueda escribir, por ejemplo `C:\Development\flutter`, y agregá su carpeta `bin` a PATH. No copies el SDK de la PC original ni las carpetas `.dart_tool`, `build` o `node_modules`.

Después de instalar las herramientas, abrí una terminal nueva y comprobá:

```powershell
git --version
node --version
npm.cmd --version
java -version
flutter --version
flutter doctor -v
```

`JAVA_HOME` debe apuntar a la carpeta del **JDK**, no a `bin` ni a `java.exe`. Los accesos respetan un `JAVA_HOME` válido; si falta, consultan el Java de PATH y detectan su carpeta real. No dependen de `C:\Program Files\Java\jdk-21`. Si tenés varias versiones, podés seleccionar una para la terminal actual antes de iniciar:

```powershell
# Reemplazá la ruta por la carpeta de tu JDK instalado.
$env:JAVA_HOME = 'C:\Program Files\Eclipse Adoptium\jdk-21'
$env:PATH = (Join-Path $env:JAVA_HOME 'bin') + ';' + $env:PATH
```

Los avisos de `flutter doctor` sobre Visual Studio para aplicaciones Windows de escritorio no impiden compilar este proyecto para web o Android.

### Android Studio

Abrí **Settings → Languages & Frameworks → Android SDK** y prepará:

1. **SDK Platforms:** Android API 36.
2. **SDK Tools:** Android SDK Platform-Tools, Android SDK Build-Tools, Android Emulator y Android SDK Command-line Tools (latest).
3. Revisá las licencias con `flutter doctor --android-licenses` y aceptá personalmente las que correspondan.
4. Comprobá la aceleración del emulador. En Windows, seguí la [guía oficial de aceleración](https://developer.android.com/studio/run/emulator-acceleration); la virtualización debe estar habilitada en el equipo.

Los scripts buscan el SDK en `ANDROID_HOME`, luego en `ANDROID_SDK_ROOT` y finalmente en `%LOCALAPPDATA%\Android\sdk`. Si lo instalaste en otra ubicación, configurá `ANDROID_HOME`. Por ejemplo, para esta terminal:

```powershell
$env:ANDROID_HOME = 'D:\Android\Sdk'
& "$env:ANDROID_HOME\emulator\emulator.exe" -accel-check
```

El inicio descarga la imagen `system-images/android-36/google_apis/x86_64` si falta y crea `DeclaraUCR_API36`. Soporta la herramienta nueva `android.exe sdk install` y el `sdkmanager.bat` clásico. Gradle descarga los componentes adicionales que requiera la versión de Flutter; mantené Internet disponible durante la primera compilación.

## 3. Descargar el repositorio

```powershell
git clone https://github.com/JoseDanielSM/declara-ucr-android.git
cd declara-ucr-android
```

El repositorio es privado. Usá la cuenta propietaria o una cuenta autorizada; Git Credential Manager puede pedir el inicio de sesión de GitHub. También se puede descargar **Code → Download ZIP**, extraerlo y abrir la carpeta exterior. Esa opción no necesita Git para ejecutar la aplicación.

La carpeta exterior incluye `Preparar-DeclaraUCR.cmd`, `Iniciar-DeclaraUCR.cmd`, `Iniciar-DeclaraUCR-Android.cmd` y `Detener-DeclaraUCR.cmd`. Dentro está el proyecto `horario_ucr-main/`. Los accesos calculan las rutas a partir de su propia ubicación, por lo que el nombre de la carpeta clonada puede cambiar y puede contener espacios.

## 4. Primera preparación

Desde la carpeta exterior:

```powershell
.\Preparar-DeclaraUCR.cmd
```

Ese acceso comprueba Node 24, Flutter, JDK y herramientas Android; instala las dependencias con los archivos de versiones de las tres carpetas npm y ejecuta `flutter pub get`. No instala los SDK del sistema ni acepta licencias Android automáticamente. No modifica la política de PowerShell de Windows: los accesos especifican la política solo para el proceso que ejecutan.

Para preparar únicamente web:

```powershell
.\Preparar-DeclaraUCR.cmd -WebOnly
```

Para comprobar las herramientas sin instalar dependencias ni iniciar servicios:

```powershell
.\Preparar-DeclaraUCR.cmd -CheckOnly
```

Si aparece un error, corregí el componente indicado y repetí la preparación. Volvé a abrir la terminal después de cambiar PATH o las variables del sistema. La preparación puede repetirse, pero no la ejecutes mientras se están compilando otras tareas del mismo proyecto.

## 5. Iniciar y detener

### Android

```powershell
.\Iniciar-DeclaraUCR-Android.cmd
```

Prepara o recupera Firebase local y notificaciones, inicia el AVD en `emulator-5554`, compila una APK **debug local** con entrada `lib/main.dart`, la instala y abre DeclaraUCR. Esperá el mensaje de finalización. Si otro AVD ocupa el puerto 5554, cerrá ese AVD antes de iniciar este acceso.

La APK recién compilada queda en `horario_ucr-main/build/app/outputs/flutter-apk/app-debug.apk`. No se guarda en Git porque se genera desde el código. Instalar solo esta APK no prepara Firebase en la PC; mantené los servicios encendidos.

### Web

```powershell
.\Iniciar-DeclaraUCR.cmd
```

Compila la web y abre [http://127.0.0.1:7357](http://127.0.0.1:7357). Android y web comparten las cuentas y documentos locales de esa instalación. La sesión web se vuelve a pedir al recargar; Android usa su sesión nativa.

### Cierre y conservación de datos

```powershell
.\Detener-DeclaraUCR.cmd
```

Exporta Authentication, Firestore y Storage a `horario_ucr-main/.local/firebase-data/` y después apaga los procesos que inició el proyecto, comprobando su identidad. El siguiente inicio importa ese respaldo y crea únicamente los datos iniciales que falten. Después podés cerrar la ventana del emulador.

No alcanza con cerrar una consola o apagar Windows para garantizar la exportación más reciente. Si la exportación falla, el acceso deja los servicios encendidos y muestra el error para que puedas reintentar. `.local/` permanece fuera de Git.

## 6. Cuentas iniciales y comprobación de uso

| Cuenta | Rol |
| --- | --- |
| `declarante@local.test` | Declarante |
| `superior@local.test` | Superior jerárquico |
| `rrhh@local.test` | Recursos Humanos |
| `admin@local.test` | Administración |

**Contraseña:** `PruebaUCR2026!`. Los datos son ficticios. El primer inicio crea el período `2026-II` habilitado y una declaración de ejemplo; no necesitas crear usuarios ni modificar roles a mano.

Comprobación breve: ingresá como declarante, creá un borrador sin todos los datos, guardalo, volvé a Trámites y abrilo. En el horario obligatorio, lunes 08:00–12:00 y 11:00–14:00 debe informar el traslape 11:00–12:00 e impedir validar. Al corregir el segundo bloque a 13:00–14:00 y completar los datos y un nombramiento UCR de fracción 1/8, la jornada de cinco horas puede validarse. Los demás roles continúan el flujo de revisión, firmas internas y RRHH.

El guardado confirmado requiere el servidor local. No se implementa una cola de guardado sin conexión. Las firmas son registros internos y no equivalen a firma digital certificada.

## 7. Arquitectura, puertos y configuración

| Componente | Dirección desde la PC | Desde Android Emulator |
| --- | --- | --- |
| Web compilada | `http://127.0.0.1:7357` | Se usa la aplicación nativa |
| Authentication | `127.0.0.1:9099` | `10.0.2.2:9099` |
| Firestore | `127.0.0.1:8180` | `10.0.2.2:8180` |
| Functions, `us-east1` | `127.0.0.1:5001` | `10.0.2.2:5001` |
| Storage | `127.0.0.1:9199` | `10.0.2.2:9199` |
| Notificaciones | `ws://127.0.0.1:8080` | `ws://10.0.2.2:8080` |
| Consola Firebase local | `http://127.0.0.1:4000` | Consultar en navegador de la PC |

También se reservan 4400, 4500 y 9299 para coordinación de los emuladores. Los servicios escuchan solo en la interfaz local de la PC. La dirección `10.0.2.2` es el acceso especial del emulador Android a esa PC, no la dirección de otro equipo de la red.

`Local-Common.ps1` configura Java y las variables de los servicios para los procesos de la aplicación. `firebase.local.json` fija el proyecto de demostración y los puertos. `seed-local.cjs` rechaza ejecutarse fuera de esos emuladores. La configuración original de Internet se conserva en `firebase.json`, `.firebaserc` y `lib/firebase_options.dart`; usá los accesos documentados para la demostración local.

La [arquitectura, persistencia y restricciones por estado](../README.md) y la [matriz del laboratorio](Laboratorio_Android.md) describen los modelos y servicios reutilizados. `saveDeclarationDraft` escribe declaración, versión e historial en una transacción; validar exige los datos completos. Los clientes anteriores conservan las observaciones adicionales al omitir ese campo.

## 8. Desarrollo, pruebas y compilaciones

Abrí la carpeta exterior en VS Code. Las recomendaciones incluyen Dart y Flutter; las tareas permiten preparar, iniciar, detener y comprobar. La configuración **DeclaraUCR Android local** inicia el emulador y la aplicación antes de conectar el depurador. Para la configuración web, iniciá primero los servicios locales.

En terminal, los siguientes comandos se ejecutan **dentro de `horario_ucr-main/`**:

```powershell
flutter analyze --no-pub
flutter test --no-pub
npm.cmd run test:backend
# Con Firebase local y notificaciones encendidos:
npm.cmd run test:local
npm.cmd run test:drafts
```

Compilaciones equivalentes a las de los accesos:

```powershell
flutter build web --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=NOTIFICATIONS_WS_URL=ws://127.0.0.1:8080
flutter build apk --debug --target=lib/main.dart --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2 --dart-define=NOTIFICATIONS_WS_URL=ws://10.0.2.2:8080
```

Para depurar Android con los servicios y el AVD encendidos:

```powershell
flutter run -d emulator-5554 --disable-dds --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2 --dart-define=NOTIFICATIONS_WS_URL=ws://10.0.2.2:8080
```

No omitas `USE_FIREBASE_EMULATORS=true` en una ejecución manual de pruebas: sin esa opción, el arranque selecciona la configuración original. Las pruebas integrales crean documentos ficticios adicionales.

El recorrido instrumentado, capturas y video se reproducen con `Run-Android-Evidence.ps1`; la recuperación tras cierre se describe en [Laboratorio Android](Laboratorio_Android.md). Después de `flutter drive`, ejecutá el inicio Android normal para reconstruir `app-debug.apk` con `lib/main.dart`: el archivo temporal de compilación podría contener la entrada de pruebas.

## 9. Solución de problemas

| Síntoma | Revisión o solución |
| --- | --- |
| No se reconoce Flutter, Node o Java | Instalá el componente, corregí PATH y abrí otra terminal. Ejecutá la preparación con `-CheckOnly`. |
| JDK no compatible | Usá JDK 21 y un `JAVA_HOME` válido; ejecutá `java -version`. El detector admite 21 o superior. |
| Falta Android SDK o `avdmanager` | Revisá `ANDROID_HOME` y habilitá Command-line Tools (latest), Emulator y Platform-Tools en SDK Manager. |
| Licencias o descarga SDK rechazadas | Revisá `flutter doctor -v` y `flutter doctor --android-licenses`; completá las licencias y reintentá con Internet. |
| Emulador lento o no inicia | Comprobá virtualización y aceleración; cerrá un AVD distinto en 5554; liberá memoria y disco. |
| Puerto ocupado | Cerrá la otra instancia del proyecto con su acceso de detener; revisá el puerto indicado. No inicies dos copias del backend simultáneamente en la misma PC. |
| No conecta desde Android | Usá los accesos locales y `10.0.2.2`; comprobá que Firebase y WebSocket siguen encendidos. Un teléfono físico requiere otra configuración. |
| CLI o paquetes faltantes | Repetí `Preparar-DeclaraUCR.cmd`; los tres archivos de versiones deben permanecer en el clon. |
| npm avisa `EBADENGINE` sobre Node 22 en Functions o WebSocket | Es la referencia del despliegue original. La demostración usa Node 24 y `firebase.local.json` selecciona explícitamente ese runtime. Los comandos de la guía fueron comprobados con Node 24. |
| Flutter no conecta al depurador | Probá `--disable-dds` como en los comandos incluidos. Las pruebas instrumentadas fijan puertos 53102/53103. |
| Advertencia de Kotlin/Gradle | Algunos plugins Firebase de la versión fijada avisan sobre compatibilidad futura; las compilaciones comprobadas terminan correctamente. No actualices paquetes a ciegas para ocultar el aviso. |
| Arranque incompleto | Consultá `.local/firebase.log`, `.local/firebase-errors.log` y registros de notificaciones. Usá el acceso de detener antes de reiniciar. |
| No aparecen trámites de la PC anterior | Es un entorno local nuevo. Recuperá un respaldo completo como se indica abajo si necesitas esos documentos. |

Para trasladar tus datos, primero detené correctamente la instalación de origen. Copiá **toda** su carpeta `.local/firebase-data/` a la misma ruta relativa del clon de destino, con los servicios de destino apagados. No copies `processes.json`, archivos de SDK ni el resto de `.local`: los identificadores de procesos pertenecen a la otra PC. Guardá aparte cualquier respaldo anterior del destino antes de reemplazarlo. El siguiente inicio importa los datos y conserva las cuentas existentes.

## 10. Referencia para ejecución manual del backend

Los accesos Windows son la ruta soportada. En otro sistema, con Node 24, Java 21, Flutter y dependencias instaladas, el mismo backend puede iniciarse manualmente. Desde la carpeta Flutter, definí en las terminales los valores siguientes con la sintaxis de tu sistema:

```text
GCLOUD_PROJECT=demo-declaraucr-local
GOOGLE_CLOUD_PROJECT=demo-declaraucr-local
FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099
FIRESTORE_EMULATOR_HOST=127.0.0.1:8180
FIREBASE_STORAGE_EMULATOR_HOST=127.0.0.1:9199
HOST=127.0.0.1
PORT=8080
```

1. Instalá `npm ci` en la carpeta Flutter, `functions/` y `websocket_server/`; ejecutá `flutter pub get` y la compilación web local de la sección 8.
2. En una terminal, ejecutá `node node_modules/firebase-tools/lib/bin/firebase.js emulators:start --config firebase.local.json --project demo-declaraucr-local --only auth,firestore,functions,storage,hosting`. Podés añadir `--import .local/firebase-data --export-on-exit .local/firebase-data` si ya existe un respaldo; creá la carpeta de salida para exportar.
3. Cuando los emuladores estén listos, en otra terminal con las variables anteriores ejecutá `node scripts/seed-local.cjs`.
4. En una tercera terminal con esas variables ejecutá `node websocket_server/server.js`.
5. Abrí la web local o ejecutá Flutter con los parámetros de emuladores. Revisá la exportación al cerrar; el manejo automático de procesos de los `.cmd/.ps1` es específico de Windows.

Esta referencia no equivale a una instalación completa comprobada en Linux o macOS ni configura un AVD para procesadores ARM.

## 11. Verificación y referencias

La versión Android inicial fue verificada en Windows con las pruebas y evidencias registradas en `evidence/android/`. Para preparar este repositorio se comprueban también el detector de requisitos y una copia limpia en una ruta distinta con espacios, sin copiar cachés, SDK ni datos locales. El informe de ese empaquetado está en [Verificación de portabilidad](Verificacion_portabilidad.md). No se ha ejecutado en una segunda PC física: las herramientas del sistema deben instalarse en el destino siguiendo esta guía.

Fuentes de instalación: [Flutter](https://docs.flutter.dev/install), [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite/install_and_configure), [Android Emulator](https://developer.android.com/studio/run/emulator-acceleration), [Node.js](https://nodejs.org/en/download) y [Temurin](https://adoptium.net/temurin/releases/?version=21). El código original y las fuentes de identidad visual se reconocen en el README del repositorio y la documentación del laboratorio.
