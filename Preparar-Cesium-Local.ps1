# Super-Trip: instala CesiumJS 1.133.0 localmente y abre el prototipo.
# No solicita, lee, copia ni almacena tokens. Descarga dependencias publicas de npm.
# Ejecutar desde PowerShell en la carpeta que contiene este script y el HTML.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$html = Join-Path $root "Prototipo-Terreno-3D.html"
$dest = Join-Path $root "vendor\Cesium"
$temp = Join-Path $env:TEMP "super-trip-cesium-1.133.0"
if (-not (Test-Path -LiteralPath $html)) { throw "Falta Prototipo-Terreno-3D.html en la misma carpeta del script." }
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
  throw "No se encontro npm. Instala Node.js LTS desde https://nodejs.org/ y vuelve a ejecutar este script."
}
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
  throw "No se encontro Python. Instala Python y vuelve a ejecutar este script."
}
if (-not (Test-Path -LiteralPath (Join-Path $dest "Cesium.js"))) {
  Write-Host "Descargando CesiumJS 1.133.0 desde npm (sin ejecutar scripts de instalacion)..."
  New-Item -ItemType Directory -Path $temp -Force | Out-Null
  & npm install --prefix $temp --no-save --ignore-scripts --no-audit --no-fund --package-lock=false cesium@1.133.0
  if ($LASTEXITCODE -ne 0) { throw "npm no pudo descargar CesiumJS." }
  $source = Join-Path $temp "node_modules\cesium\Build\Cesium"
  foreach ($needed in @("Cesium.js", "Workers", "Assets", "Widgets", "ThirdParty")) {
    if (-not (Test-Path -LiteralPath (Join-Path $source $needed))) { throw "Distribucion incompleta: falta $needed." }
  }
  New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force | Out-Null
  Copy-Item -LiteralPath $source -Destination $dest -Recurse -Force
}
foreach ($needed in @("Cesium.js", "Workers", "Assets", "Widgets", "ThirdParty")) {
  if (-not (Test-Path -LiteralPath (Join-Path $dest $needed))) { throw "Cesium local incompleto: falta $needed." }
}
Write-Host "Cesium local verificado. Abre http://localhost:8765/Prototipo-Terreno-3D.html"
Write-Host "Mantener esta ventana abierta durante la prueba. Para detener: Ctrl+C."
& python -m http.server 8765 --bind 127.0.0.1 --directory $root
