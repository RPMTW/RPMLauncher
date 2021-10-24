pushd "%CD%"

CD /D "%~dp0"

:: 複製檔案到暫存資料夾

Powershell.exe cp ./CERTIFICATE.pfx $Env:temp
Powershell.exe cp ./rpmlauncher.msix $Env:temp

:: 安裝憑證

Powershell.exe Import-PfxCertificate -Password (ConvertTo-SecureString -AsPlainText -Force "rpmtw") -FilePath $Env:temp/CERTIFICATE.pfx -CertStoreLocation Cert:\LocalMachine\Root

:: 執行MSIX安裝程式

%TEMP%/rpmlauncher.msix

exit 0