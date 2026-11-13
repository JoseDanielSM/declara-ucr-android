# Estado de entrega

Fecha de revisión: 12 de noviembre de 2026.

APK entregado: `DeclaraUCR-telefono.apk`, versión `1.0.1`, código `2`, Android mínimo API 24. Firma APK v2 verificada, certificado coincidente con la versión anterior. SHA-256 del archivo: `28b8df30ea2ffa68f1446a3f9417225dd9b15adc903ed0723ddcda0d4a885989`.

- Firebase Android registrado en DeclaraHorario-UCR, paquete cr.ac.ucr.declaraucr.
- APK release **1.0.1+2**, con la misma firma privada de la entrega anterior, generado en output/android/DeclaraUCR-telefono.apk. Compilación web release y análisis Flutter sin problemas.
- 114 pruebas Flutter y 67 del validador aprobadas. Evidencias anteriores corresponden a los emuladores y datos ficticios.
- Cuatro funciones móviles publicadas con josedanielsm17@gmail.com: saveDeclarationDraft, validateMobileDeclaration, newMobileDeclarationVersion y markMobileNotificationsRead. No se sustituyeron las funciones originales ni las reglas del proyecto.
- El usuario aceptó su invitación y la consola confirmó su rol Propietario. También autorizó expresamente habilitar la invocación desde Internet de las cuatro funciones. Se configuró roles/run.invoker para allUsers exclusivamente en sus cuatro servicios Cloud Run, conservando las demás vinculaciones. Los handlers mantienen la autenticación Firebase y las comprobaciones de permisos.
- Verificación externa de las cuatro URLs: **HTTP 401 / UNAUTHENTICATED**, emitido por cada handler al enviar una solicitud sin sesión. El bloqueo anterior HTTP 403 de infraestructura quedó resuelto. Esta comprobación acredita acceso de red y rechazo sin sesión; no sustituye una operación completa con credenciales reales.
- Las tarjetas Total, Pendientes, Finalizadas y Borrador abren Trámites con el filtro correspondiente, limpian búsquedas previas y permiten resultados vacíos. Pendientes incluye borradores y excluye FINALIZADA y ANULADA. Se verificaron pulsación, teclado y acción accesible a 320, 360 y 600 dp con texto al 200 %.
- No se han probado las credenciales de usuarios reales ni todos los roles en un teléfono físico.
- Revisión documental contra las páginas 2–5 del PDF: ambos README incluyen las cuatro preguntas completas y sus respuestas; el README principal incluye estructura, persistencia, dificultades, matriz R1–R6 y enlaces a las evidencias. La guía del laboratorio relaciona las cinco pruebas y los entregables con sus archivos y distingue la ejecución local original de la distribución posterior para teléfono.

La limpieza retiró informes antiguos, resultados duplicados y documentos históricos del proyecto activo. Se guardaron en .local/archivo-historico de la carpeta exterior, fuera de Git. Los datos locales Firebase y las claves de firma se conservaron.

El error original run.services.setIamPolicy se resolvió con la cuenta autorizada, ya propietaria. El despliegue de actualización del CLI no reparó por sí solo la política omitida durante la creación; se corrigió y verificó la política de los cuatro servicios. La guía Android documenta cómo restaurarla con herramientas oficiales si vuelve a ocurrir.
