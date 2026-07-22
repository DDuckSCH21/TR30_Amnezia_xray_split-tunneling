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
$scpArgs = @("-O", "-r", $etc, $usr, $www, "${Router}:/")
& scp @scpArgs
if ($LASTEXITCODE -ne 0) {
    Write-Host "Повтор без -O..."
    & scp -r $etc $usr $www "${Router}:/"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host "Права, rc.local (TPROXY), uhttpd..."
$remote = @'
chmod +x /usr/bin/singbox-apply-domains /usr/bin/singbox-tproxy-up /www/cgi-bin/singbox-domains 2>/dev/null || true
if [ -f /etc/rc.local ] && ! grep -q singbox-tproxy-up /etc/rc.local; then
  sed -i '/^exit 0/i sleep 8\n/usr/bin/singbox-tproxy-up' /etc/rc.local
fi
rm -f /tmp/luci-indexcache
/etc/init.d/uhttpd restart 2>/dev/null || true
'@
ssh $Router $remote

$hostOnly = ($Router -split "@")[-1]
Write-Host "Готово (config.json, domains.list, singbox-tproxy). На роутере см. README.md шаг 3."
Write-Host "Веб: http://${hostOnly}/cgi-bin/singbox-domains"
