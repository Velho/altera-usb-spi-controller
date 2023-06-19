# quartus_env.ps1
# setup the quartus env (tested with quartus 13 sp1)
# after executing env script, quartus found from $env::QUARTUS_PATH

# set default quartus toolchain path
$QuartusSh_Exe = "quartus_sh.exe"
$Default_QuartusPath = "C:\altera\13.0sp1\quartus\bin"
$QuartusShPath = Join-Path $Default_QuartusPath $QuartusSh_Exe

# quartus_sh.exe exists in default path
if (Test-Path $QuartusShPath) {
    [Environment]::SetEnvironmentVariable("QUARTUS_PATH", $Default_QuartusPath, "User")
} else {
    # request user to input custom path
    Write-Host "Quartus path not found at $Default_QuartusPath"
    $User_QuartusPath = Read-Host "Enter the path to Quartus (e.g., C:\path\to\quartus\bin)"

    $User_QuartusShPath = Join-Path $User_QuartusPath $QuartusSh_Exe
    if (Test-Path $User_QuartusShPath) {
        [Environment]::SetEnvironmentVariable("QUARTUS_PATH", $User_QuartusShPath, "User")
    } else {
        Write-Host "Invalid Quartus path. Aborting."
        Exit 1
    }
}