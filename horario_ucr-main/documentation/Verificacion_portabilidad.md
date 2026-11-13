# Verificación de portabilidad

La preparación se ejecutó en una copia limpia, ubicada en otra carpeta con espacios, sin copiar node_modules, build, .dart_tool ni datos Firebase locales. Se instalaron las dependencias desde los archivos de versiones, incluido Firebase CLI 15.34.0.

Resultados de esa revisión del 11 de noviembre de 2026: análisis Flutter sin problemas, 110 pruebas Flutter y 67 del validador aprobadas, compilación web y APK de desarrollo correctas, 12 comprobaciones del flujo local y 13 de borradores/permisos aprobadas desde la copia limpia contra los emuladores de la PC. Se compartieron los SDK instalados; no fue una segunda PC física.

La revisión posterior para teléfono se documenta en Estado_entrega.md: APK release 1.0.1+2 firmado y Firebase Android original configurado, cuatro funciones publicadas y permisos de invocación habilitados con autorización del usuario. Las cuatro URLs devolvieron HTTP 401 / UNAUTHENTICATED ante solicitudes sin sesión. Se aprobaron 114 pruebas Flutter, 67 del validador y las compilaciones Android/web. Las evidencias locales no sustituyen una comprobación completa con cuentas reales en un teléfono físico.
