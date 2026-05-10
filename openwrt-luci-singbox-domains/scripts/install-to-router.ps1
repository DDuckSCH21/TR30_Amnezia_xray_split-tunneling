# Копирует bundle на OpenWrt (PowerShell, Windows 10+ с OpenSSH Client).
# Установка: Параметры → Приложения → Дополнительные компоненты → Клиент OpenSSH
#
# Запуск из каталога openwrt-luci-singbox-domains:
#   .\scripts\install-to-router.ps1
#   $env:ROUTER = "root@192.168.1.1"; .\scripts\install-to-router.ps1

$ErrorActionPreference = "Stop"
$Router = if ($env:ROUTER) { $env:ROUTER } else { "root@192.168.1.1" }
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BundleRoot = Join-Path (Split-Path -Parent $ScriptDir) "root"

if (-not (Test-Path (Join-Path $BundleRoot "etc"))) {
    Write-Error "Не найден каталог root/. Запускайте скрипт из репозитория openwrt-luci-singbox-domains."
}

$etc = Join-Path $BundleRoot "etc"
$usr = Join-Path $BundleRoot "usr"
$www = Join-Path $BundleRoot "www"

Write-Host "Копирование на $Router ..."
# Dropbear на OpenWrt: флаг -O (legacy scp), как на macOS
$scpArgs = @("-O", "-r", $etc, $usr, $www, "${Router}:/")
& scp @scpArgs
if ($LASTEXITCODE -ne 0) {
    Write-Host "Повтор без -O..."
    & scp -r $etc $usr $www "${Router}:/"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host "Права и uhttpd..."
ssh $Router "chmod +x /usr/bin/singbox-apply-domains /www/cgi-bin/singbox-domains 2>/dev/null; rm -f /tmp/luci-indexcache; /etc/init.d/uhttpd restart 2>/dev/null || true"

$hostOnly = ($Router -split "@")[-1]
Write-Host "Готово (в т.ч. /etc/sing-box/config.json). На роутере см. README.md шаг 3."
Write-Host "Веб: http://${hostOnly}/cgi-bin/singbox-domains"
