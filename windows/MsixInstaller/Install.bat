pushd "%CD%"

if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)

CD /D "%~dp0"

:: 安裝憑證

echo "Installing Certificate..."

Powershell.exe Import-PfxCertificate -Password (ConvertTo-SecureString -AsPlainText -Force "rpmtw") -FilePath ./CERTIFICATE.pfx -CertStoreLocation Cert:\LocalMachine\Root

:: 執行MSIX安裝程式

echo "Run Installer..."

Powershell.exe ./rpmlauncher.msix
