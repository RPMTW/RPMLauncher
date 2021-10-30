pushd "%CD%"

CD /D "%~dp0"

:: 安裝憑證

Powershell.exe Import-PfxCertificate -Password (ConvertTo-SecureString -AsPlainText -Force "rpmtw") -FilePath ./CERTIFICATE.pfx -CertStoreLocation Cert:\LocalMachine\Root

:: 執行MSIX安裝程式

./rpmlauncher.msix

exit 0