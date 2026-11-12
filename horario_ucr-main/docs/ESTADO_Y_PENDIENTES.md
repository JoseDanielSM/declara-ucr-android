# Estado del proyecto — 11 de noviembre de 2026

La aplicación compila y se ejecuta en esta PC. El entorno de prueba se inicia con `Iniciar-DeclaraUCR.cmd`, abre http://127.0.0.1:7357 y utiliza Firebase Auth, Firestore, Functions, Storage y Hosting emulados, junto con el servidor local de notificaciones.

Las cuentas de los cuatro roles, su contraseña y las instrucciones de cierre y guardado están en el README.

## Verificado

- Análisis Flutter sin problemas y 96 pruebas Flutter aprobadas.
- 67 pruebas del validador del servidor aprobadas.
- 12 comprobaciones integrales locales: acceso con los cuatro roles, consulta de superiores, WebSocket autenticado, guardado y validación, firmas, envío a RRHH, recepción, finalización, archivo y descarga de PDF.
- Exportación e importación de cuentas, declaraciones y PDF entre cierres e inicios.
- Inicio de sesión y validación de una declaración desde el navegador.

Los resultados recientes se guardan en `.local/flutter-tests.log`, `.local/local-checks.json` y `.local/restart-check.json`. La carpeta `.local` contiene únicamente datos y registros del entorno de prueba y está excluida de Git.

## Correcciones para ejecutarlo

- Importaciones incorrectas de Firebase y del panel en `lib/main.dart`.
- Fuente de iconos Cupertino que faltaba en las dependencias.
- Pruebas del formulario que todavía buscaban campos y botones de una interfaz anterior.
- Configuración independiente de emuladores, cuentas iniciales, inicio y cierre compatibles con Windows PowerShell y persistencia de datos de prueba.
- Sesiones locales temporales para evitar la restauración de usuarios ficticios contra Firebase de Internet al recargar.

La interfaz administrativa de roles y períodos ya existe en `lib/pages/admin_page.dart`. El servidor implementa guardado y validación de declaraciones, nuevas versiones, listado de superiores y archivo/descarga de PDF. Algunos documentos y scripts antiguos del ZIP describen versiones anteriores o contienen rutas de otra computadora; para ejecutar y comprobar esta instalación, usar los accesos y comandos del README.

## Límites de lo comprobado

- No se desplegaron cambios ni se comprobó el proyecto Firebase de Internet.
- Las firmas son electrónicas internas, no firmas digitales certificadas.
- La comprobación del almacenamiento usa un PDF sencillo; no certifica el diseño institucional del formulario generado por la interfaz.
- Quedan fuera de esta puesta en marcha una auditoría completa de seguridad, las pruebas exhaustivas de concurrencia y la validación institucional del PDF.
- Esta copia descargada no contiene un repositorio Git.
