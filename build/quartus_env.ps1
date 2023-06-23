# quartus_env.ps1
# setup the quartus env (tested with quartus 13 sp1)
# after executing env script, quartus found from $env::QUARTUS_PATH

# set default quartus toolchain path
$QuartusSh_Exe = "quartus_sh.exe"
$Default_QuartusPath = "C:\altera\13.0sp1\quartus\bin"
$QuartusShellPath = Join-Path $Default_QuartusPath $QuartusSh_Exe

# quartus_sh.exe exists in default path
if (Test-Path $QuartusShellPath) {
    [Environment]::SetEnvironmentVariable("QUARTUS_PATH", $Default_QuartusPath, "User")
    [Environment]::SetEnvironmentVariable("QUARTUS_SHELL_PATH", $QuartusShellPath, "User")
} else {
    # request user to input custom path
    Write-Host "Quartus path not found at $Default_QuartusPath"
    $User_QuartusPath = Read-Host "Enter the path to Quartus (e.g., C:\path\to\quartus\bin)"

    $User_QuartusShellPath = Join-Path $User_QuartusPath $QuartusSh_Exe
    if (Test-Path $User_QuartusShellPath) {
        [Environment]::SetEnvironmentVariable("QUARTUS_PATH", $User_QuartusPath, "User")
        [Environment]::SetEnvironmentVariable("QUARTUS_SHELL_PATH", $User_QuartusShellPath, "User")
    } else {
        Write-Host "Invalid Quartus path. Aborting."
        Exit 1
    }
}