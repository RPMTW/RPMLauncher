pushd "%CD%"

CD /D "%~dp0"

:: 安裝憑證

echo "安裝憑證中.."

Powershell.exe Import-PfxCertificate -Password (ConvertTo-SecureString -AsPlainText -Force "rpmtw") -FilePath ./CERTIFICATE.pfx -CertStoreLocation Cert:\LocalMachine\Root

:: 執行MSIX安裝程式

echo "執行安裝程式中..."

./rpmlauncher.msix

exit 0