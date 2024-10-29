# Definir rutas locales y URL del listado de mods en GitHub
$local_mods = "$env:APPDATA\.minecraft\mods"
$mod_list_url = "https://github.com/Samicaseres/Modpack/raw/main/modlist.txt"
$temp_modlist = "$env:TEMP\modlist.txt"  # Lista descargada de GitHub con URLs y nombres
$temp_local_names = "$env:TEMP\local_mods_names.txt"  # Archivo temporal solo con nombres locales

# Eliminar archivos temporales si existen antes de iniciar el proceso
if (Test-Path $temp_modlist) {
    Remove-Item -Path $temp_modlist -ErrorAction SilentlyContinue
    Write-Host "Archivo temporal $temp_modlist eliminado."
} else {
    Write-Host "Archivo temporal $temp_modlist no encontrado."
}

if (Test-Path $temp_local_names) {
    Remove-Item -Path $temp_local_names -ErrorAction SilentlyContinue
    Write-Host "Archivo temporal $temp_local_names eliminado."
} else {
    Write-Host "Archivo temporal $temp_local_names no encontrado."
}

# Descargar la lista de mods desde GitHub (con URLs y nombres)
Invoke-WebRequest -Uri $mod_list_url -OutFile $temp_modlist
$mods_to_download = Get-Content $temp_modlist

# Crear listas de nombres de mods de GitHub y locales
$github_mod_names = @()
foreach ($mod in $mods_to_download) {
    $mod_url, $mod_name = $mod -split ","
    $github_mod_names += $mod_name
}

# Generar lista actualizada de nombres locales de mods
$local_files = Get-ChildItem -Path $local_mods -Filter *.jar | Select-Object -ExpandProperty Name
Set-Content -Path $temp_local_names -Value $local_files

# Crear listas de mods para descargar y eliminar
$mods_a_descargar = @()
$mods_a_eliminar = @()
$debe_descargar = $false
$debe_eliminar = $false

# Mostrar todas las variables en la consola antes de proceder
Write-Host "Contenido de Variables:"
Write-Host "Ruta local de mods: $local_mods"
Write-Host "URL de la lista de mods: $mod_list_url"
Write-Host "Ruta temporal de modlist: $temp_modlist"
Write-Host "Ruta temporal de nombres locales: $temp_local_names"
Write-Host "Nombres de mods en GitHub:"
$github_mod_names | ForEach-Object { Write-Host $_ }
Write-Host "Mods locales actuales:"
$local_files | ForEach-Object { Write-Host $_ }

# Comparar lista de GitHub con mods locales para determinar mods a descargar
foreach ($mod in $mods_to_download) {
    $mod_url, $mod_name = $mod -split ","
    
    # Si el mod de la lista no está en los archivos locales, se añade a la lista de descarga
    if (-not ($local_files -contains $mod_name)) {
        Write-Host "Se necesita descargar: $mod_name"
        $mods_a_descargar += $mod_name  # Agregar a lista de descarga solo el nombre
        $debe_descargar = $true
    }
}

# Comparar lista de mods locales con nombres de GitHub para determinar mods a eliminar
foreach ($local_file in $local_files) {
    if (-not ($github_mod_names -contains $local_file) -and ($local_file -notmatch "Xaeros") -and ($local_file -notmatch "Oh_The_Biomes_You'll_Go")) {
        Write-Host "Marcando para eliminar: $local_file"
        $mods_a_eliminar += $local_file  # Agregar a lista de eliminación
        $debe_eliminar = $true
    }
}

# Mostrar listas de descarga y eliminación antes de proceder
Write-Host "Mods a descargar:"
$mods_a_descargar | ForEach-Object { Write-Host $_ }
Write-Host "Mods a eliminar:"
$mods_a_eliminar | ForEach-Object { Write-Host $_ }

# Verificar si la carpeta de mods existe, si no, crearla
if (-not (Test-Path -Path $local_mods)) {
    New-Item -ItemType Directory -Path $local_mods -Force
    Write-Host "Carpeta de mods creada en: $local_mods"
}

# Ejecutar eliminación solo si la bandera $debe_eliminar es true
if ($debe_eliminar) {
    foreach ($mod_name in $mods_a_eliminar) {
        Write-Host "Eliminando mod obsoleto: $mod_name"
        Remove-Item "$local_mods\$mod_name"
    }
} else {
    Write-Host "No hay mods para eliminar."
}

# Ejecutar descargas solo si la bandera $debe_descargar es true
if ($debe_descargar) {
    foreach ($mod_name in $mods_a_descargar) {
        $mod_url = ($mods_to_download | Where-Object { $_ -match [regex]::Escape($mod_name) }) -split "," | Select-Object -First 1
        Write-Host "Descargando $mod_name..."
        Invoke-WebRequest -Uri $mod_url -OutFile "$local_mods\$mod_name" -UseBasicParsing
    }
} else {
    Write-Host "No hay mods para descargar."
}

# Limpiar archivos temporales nuevamente al finalizar y reiniciar variables
Remove-Item -Path $temp_modlist -ErrorAction SilentlyContinue
Remove-Item -Path $temp_local_names -ErrorAction SilentlyContinue

# Reiniciar las variables
$mods_to_download = @()
$github_mod_names = @()
$local_files = @()
$mods_a_descargar = @()
$mods_a_eliminar = @()
$debe_descargar = $false
$debe_eliminar = $false

Write-Host "Archivos temporales eliminados y variables reiniciadas."

# Mostrar mensaje final
if ($debe_descargar -or $debe_eliminar) {
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show("Mods actualizados correctamente.")
} else {
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show("Todos los mods ya estan actualizados.")
}

Write-Host "Proceso completado."
