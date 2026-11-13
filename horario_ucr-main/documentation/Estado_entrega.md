# Estado de entrega

Fecha de revisión: 12 de noviembre de 2026.

- Firebase Android registrado en DeclaraHorario-UCR, paquete cr.ac.ucr.declaraucr.
- APK release con firma propia generado en output/android/DeclaraUCR-telefono.apk.
- 110 pruebas Flutter aprobadas. Evidencias anteriores corresponden a los emuladores y datos ficticios.
- Cuatro funciones móviles creadas: saveDeclarationDraft, validateMobileDeclaration, newMobileDeclarationVersion y markMobileNotificationsRead. No se sustituyeron las funciones originales ni las reglas del proyecto.
- **Pendiente:** Firebase CLI informó que la cuenta usada no pudo configurar el permiso de invocación de las funciones nuevas. El guardado y validación desde el APK no se consideran operativos en producción hasta resolverlo y probarlos con una cuenta autorizada.
- No se han probado las credenciales de usuarios reales ni todos los roles en un teléfono físico.

La limpieza retiró informes antiguos, resultados duplicados y documentos históricos del proyecto activo. Se guardaron en .local/archivo-historico de la carpeta exterior, fuera de Git. Los datos locales Firebase y las claves de firma se conservaron.

La sesión correcta de Brave se verificó en Usuarios y permisos: josedanielsm17@gmail.com tiene rol Editor. La consola exige intervención de un propietario para administrar permisos. El error concreto del despliegue fue run.services.setIamPolicy. Se usará únicamente esa cuenta; no se utilizará proyectoinfoucr@gmail.com.
