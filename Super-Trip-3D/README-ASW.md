# Super-Trip 3D — Integración Auto Sea Way mundial (experimental)

Motor: [Auto Sea Way](https://github.com/auto-sea-way/asw), release fijado **0.12.0**, MIT/Apache-2.0.

**No cambiar Cute.html ni Formal.html.** Esta integración está aislada de ambas versiones.

## Archivos
- `Super-Trip-3D-Auto-Sea-Way-Mundial.html`: versión 3D modificada, que sustituirá a `super-trip-3/index.html` solo después de respaldar la versión operativa.
- `asw-bridge.py`: puente HTTP local (127.0.0.1:8766), no expone claves en el navegador.
- `Iniciar-Auto-Sea-Way.ps1`: genera una clave local en `asw.env`, limita su ACL, ejecuta Docker exclusivamente en 127.0.0.1:3000 y arranca el puente.
- `asw.env`: **secreto local**, generado al iniciar; jamás subir a GitHub.

## Prerrequisitos
- Docker Desktop en ejecución (Linux containers). Imagen `ghcr.io/auto-sea-way/asw:0.12.0-full` (descarga de ~870 MB, grafo ~1.47 GB; RAM sugerida >=4 GB).
- Python 3 en Windows.
- Servidor existente de Super-Trip 3D en `http://127.0.0.1:8765/super-trip-3/index.html` y Cesium local.

## Uso
1. Guardar los tres archivos en la misma carpeta de trabajo, **no copiar `asw.env` a GitHub**.
2. Antes de instalar, revisar los requisitos de Docker y Python.
3. Ejecutar `Iniciar-Auto-Sea-Way.ps1` tras la advertencia de creación de clave local; mantener abierta su ventana.
4. Respaldar `C:\Super-Trip-3D\super-trip-3\index.html`; copiar la versión HTML nueva y verificar SHA256.
5. En Chrome seleccionar transporte **Barco**. Usar puertos existentes en el catálogo (78 opciones aproximadas) o introducir coordenadas sobre el agua como **latitud,longitud** en los campos de salida/llegada.
6. Para probar: **Valparaíso → Santos (puerto)**. Si el servicio no está activo, la ruta existente Valparaíso–Talcahuano sigue disponible como reserva ilustrativa.

## Seguridad y límites
- La clave reside en `asw.env` y el navegador solo llama al puente local. No se incluyen claves en GitHub/HTML.
- ASW permite cualquier par de coordenadas, **no equivale a un registro completo de nombres de todos los puertos**. El catálogo de 78 puertos es un ejemplo; para cualquier otro puerto se usan coordenadas.
- Puertos con coordenadas interiores o en tierra pueden generar segmentos terrestres (`land_legs`). La integración los rechaza por seguridad visual; usa coordenadas sobre el agua.
- ASW no contempla profundidad, corrientes, hielo estacional ni tamaño del buque. **No usar para navegación real.**
- La integración pasó comprobaciones estáticas de sintaxis; requiere prueba de extremo a extremo con Docker y Cesium en Windows.