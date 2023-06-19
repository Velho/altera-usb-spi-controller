# quartus_compile.ps1
# compiles the quartus project
# requires env to be called first
# build scripts are required to be called from the project root

# get quartus project file
$ProjectFile = Get-ChildItem -Filter "*.qpf" -File | Select-Object -First 1

if ($null -eq $ProjectFile) {
    Write-Host "No Quartus project file found (*.qpf). Aborting."
    Exit 1
}

# verify QUARTUS_PATH is set correctly.
$QuartusPath = [Environment]::GetEnvironmentVariable("QUARTUS_PATH", "User")

if ($QuartusPath -eq $null) {
    Write-Host "Quartus path is not set. Run quartus_env.ps1 to proceed."
    Exit 1
}

$QuartusShExe = "quartus_sh.exe"
$QuartusShPath = Join-Path $QuartusPath $QuartusShExe

# compile the quartus project
if (Test-Path $QuartusShPath) {
    Write-Host "Compiling Quartus project..."

    $TopLevel = [System.IO.Path]::GetFileNameWithoutExtension($ProjectFile.FullName)
    $QCompileCommand = "$QuartusShExe --flow compile `"$($TopLevel)`""
    Invoke-Expression -Command $QCompileCommand
} else {
    Write-Host "Failed to find $QuartusShExe at $QuartusShPath. Aborting."
    Exit 1
}