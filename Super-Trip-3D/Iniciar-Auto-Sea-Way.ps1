# Super-Trip 3D — Arranque local Auto Sea Way 0.12.0 + puente HTTP.
# ADVERTENCIA: crea un archivo de clave local asw.env, inicia Docker y descarga
# una imagen grande (~870 MB) con el grafo de 1.47 GB. No publica puertos externos.
$ErrorActionPreference = 'Stop'
$base = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFile = Join-Path $base 'asw.env'
$bridge = Join-Path $base 'asw-bridge.py'
try {
    if (-not (Test-Path -LiteralPath $bridge -PathType Leaf)) { throw 'Falta asw-bridge.py junto a este script.' }
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { throw 'Docker no está disponible. Instala/abre Docker Desktop antes de continuar.' }
    if (-not (Get-Command py -ErrorAction SilentlyContinue) -and -not (Get-Command python -ErrorAction SilentlyContinue)) { throw 'Python 3 no está disponible.' }
    docker info --format '{{.ServerVersion}}' *> $null
    if ($LASTEXITCODE -ne 0) { throw 'El motor Docker no está activo.' }
    if (-not (Test-Path -LiteralPath $envFile -PathType Leaf)) {
        $bytes = New-Object byte[] 32
        $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
        $key = [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
        [System.IO.File]::WriteAllText($envFile, "ASW_API_KEY=$key`n", [System.Text.UTF8Encoding]::new($false))
        # Limitar lectura y escritura al usuario actual.
        & icacls.exe $envFile '/inheritance:r' '/grant:r' "$($env:USERNAME):(R,W)" *> $null
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo restringir el acceso al archivo de clave.' }
        Remove-Variable key -ErrorAction SilentlyContinue
        Write-Host 'Clave local creada y protegida. No se mostrará.' -ForegroundColor Green
    }
    $existing = docker ps -a --filter 'name=^/supertrip-asw$' --format '{{.Names}}'
    if ($existing -eq 'supertrip-asw') {
        docker start supertrip-asw *> $null
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo iniciar el contenedor existente.' }
    } else {
        Write-Host 'Descargando y creando Auto Sea Way 0.12.0 en localhost (el archivo es grande)...' -ForegroundColor Cyan
        docker run -d --name supertrip-asw -p '127.0.0.1:3000:3000' --env-file $envFile 'ghcr.io/auto-sea-way/asw:0.12.0-full' *> $null
        if ($LASTEXITCODE -ne 0) { throw 'Falló la creación del contenedor.' }
    }
    Write-Host 'Servicio Auto Sea Way iniciado. Espera a que cargue el grafo.' -ForegroundColor Green
    Write-Host 'Iniciando puente HTTP local en el puerto 8766. Mantén esta ventana abierta.'
    if (Get-Command py -ErrorAction SilentlyContinue) { & py -3 $bridge }
    else { & python $bridge }
} catch {
    Write-Host ("ERROR: " + $_.Exception.Message) -ForegroundColor Red
}