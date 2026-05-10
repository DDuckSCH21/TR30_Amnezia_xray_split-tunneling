# Sing-box: сплит по списку + веб-редактор (OpenWrt)

## Порядок работы

1. **Заполни реквизиты** в **`root/etc/sing-box/config.json`** в репозитории (см. таблицу в **`README.md`** в корне репозитория).
2. **Запусти скрипт** установки из каталога **`openwrt-luci-singbox-domains`** (`scripts/install-to-router.sh` или `.ps1`).
3. **По SSH на роутер** — `opkg install jq sing-box`, права на скрипты, **`sing-box check`**, **`singbox-apply-domains`**, **`/etc/init.d/sing-box`**, перезапуск **uhttpd** (команды в **`README.md`**, шаг 3).

---

Редактор пишет **`/etc/sing-box/domains.list`**, **`singbox-apply-domains`** пересобирает **`route.rules`** в **`/etc/sing-box/config.json`** и перезапускает sing-box. Обычно в VPN только строки из списка, остальное — **`route.final` → direct**.

---

## На роутере кроме sing-box и UI

1. **TPROXY с LAN** в sing-box: отдельная таблица **nft** (не вшивать в `fw4` как include-файл), **`tproxy` на `127.0.0.1:12345`** (или твой порт), **`meta mark 0x1`**.
2. **`ip rule add fwmark 1 table 100`** и **`ip route replace local 0.0.0.0/0 dev lo table 100`**.
3. Порт **tproxy** inbound в **`config.json`** = порт в **nft**.

---

## Установка с компьютера (только копирование)

Копируется **`openwrt-luci-singbox-domains/root/`** → корень ФС роутера (**`etc`**, **`usr`**, **`www`**).

**macOS / Linux / Git Bash:**

```sh
cd openwrt-luci-singbox-domains
chmod +x scripts/install-to-router.sh
ROUTER=root@192.168.1.1 ./scripts/install-to-router.sh
```

**Windows (PowerShell):** **`.\scripts\install-to-router.ps1`**

**Вручную:** `scp -O -r root/etc root/usr root/www root@192.168.1.1:/` (из каталога **`openwrt-luci-singbox-domains`**).

**Редактор:** `http://<IP-роутера>/cgi-bin/singbox-domains`  
С **luci-light:** меню **System → Sing-box domains**.

---

## Список (`domains.list`)

Одна запись в строке. **`#`** в начале строки — комментарий. Домен — суффикс. **`*.example.com`** то же, что **`example.com`**. Строка с **IPv4/IPv6** и маской — **`ip_cidr`**.

Правила **`ip_cidr` → proxy** из конфига, которых нет в списке, при сохранении **пропадут**. Сохраняются из старого конфига только правила с **`port`** или **`ip_cidr` с outbound ≠ proxy`** (например LAN → direct).

У **`luci-light`** бывает **404** на Lua-страницах — пользуйтесь CGI или JS из bundle.

---

## Удаление

```sh
rm -f /usr/lib/lua/luci/controller/singbox_domains.lua \
  /usr/lib/lua/luci/view/singbox_domains.htm \
  /usr/share/luci/menu.d/luci-singbox-domains.json \
  /www/luci-static/resources/view/singbox_domains/singbox_domains.js \
  /www/cgi-bin/singbox-domains /usr/bin/singbox-apply-domains
```

---

## Если сплит не работает

Есть **nft tproxy** на порт sing-box, **`ip rule`** для **fwmark**, в **table 100** — **`local default dev lo`**, в inbound — **sniff** + **sniff_override_destination**, **`sing-box check`** без ошибок.
