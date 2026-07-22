#!/bin/sh
# Копирует bundle openwrt-luci-singbox-domains на OpenWrt по SSH/scp.
# macOS (OpenSSH 9+): нужен scp -O для Dropbear. Linux: при ошибке повтор без -O.
#
# Использование:
#   ./scripts/install-to-router.sh
#   ROUTER=root@192.168.1.1 ./scripts/install-to-router.sh
#
# Требования: ssh, scp в PATH (Windows: «Дополнительные компоненты» → OpenSSH Client).

set -e

ROUTER="${ROUTER:-root@192.168.1.1}"
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
BUNDLE_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)/root"

[ -d "$BUNDLE_ROOT/etc" ] && [ -d "$BUNDLE_ROOT/usr" ] && [ -d "$BUNDLE_ROOT/www" ] || {
	echo "Не найден каталог root/ рядом со scripts/. Запускайте из репозитория." >&2
	exit 1
}

run_scp() {
	if scp -O -r "$BUNDLE_ROOT/etc" "$BUNDLE_ROOT/usr" "$BUNDLE_ROOT/www" "$ROUTER:/"; then
		return 0
	fi
	echo "scp -O не удался (часто нормально на Linux). Повтор без -O..." >&2
	scp -r "$BUNDLE_ROOT/etc" "$BUNDLE_ROOT/usr" "$BUNDLE_ROOT/www" "$ROUTER:/"
}

echo "Копирование на $ROUTER ..."
run_scp

echo "Права, rc.local (TPROXY), uhttpd на роутере..."
ssh "$ROUTER" sh -s <<'REMOTE'
chmod +x /usr/bin/singbox-apply-domains /usr/bin/singbox-tproxy-up /www/cgi-bin/singbox-domains 2>/dev/null || true
if [ -f /etc/rc.local ] && ! grep -q singbox-tproxy-up /etc/rc.local; then
	sed -i '/^exit 0/i sleep 8\n/usr/bin/singbox-tproxy-up' /etc/rc.local
fi
rm -f /tmp/luci-indexcache
/etc/init.d/uhttpd restart 2>/dev/null || true
REMOTE

echo "Готово (config.json, domains.list, singbox-tproxy). На роутере см. README.md шаг 3."
echo "Веб: http://${ROUTER#*@}/cgi-bin/singbox-domains"
