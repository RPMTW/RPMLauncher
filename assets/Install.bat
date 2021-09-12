@echo off
pushd "%CD%"

if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)

CD /D "%~dp0"
echo %cd%
echo "安裝憑證中..."
Powershell.exe Import-PfxCertificate -Password (ConvertTo-SecureString -AsPlainText -Force "rpmtw") -FilePath .\CERTIFICATE.pfx -CertStoreLocation Cert:\LocalMachine\Root
echo "開啟Msix安裝程式中..."
Powershell.exe ./rpmlauncher.msix
pause