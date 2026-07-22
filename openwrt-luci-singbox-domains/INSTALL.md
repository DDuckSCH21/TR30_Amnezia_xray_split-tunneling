# Sing-box: сплит по списку + веб-редактор (OpenWrt)

## Порядок работы

1. **Заполни реквизиты** в **`root/etc/sing-box/config.json`** (таблица в **`README.md`**).
2. **Запусти** `scripts/install-to-router.sh` (или `.ps1`) из каталога **`openwrt-luci-singbox-domains`**.
3. **По SSH** — пакеты, `singbox-apply-domains`, `singbox-tproxy-up` (команды в **`README.md`**, шаг 3).

---

Редактор пишет **`/etc/sing-box/domains.list`**, **`singbox-apply-domains`** пересобирает **`route.rules`** и перезапускает sing-box.

## TPROXY (прозрачный прокси с LAN)

В bundle:

- **`/etc/singbox-tproxy.nft`** — таблица `inet singbox_tproxy`, TCP с `br-lan` → `127.0.0.1:12345`
- **`/usr/bin/singbox-tproxy-up`** — `fwmark` + table 100 + `nft -f`
- автозагрузка: в **`/etc/rc.local`** перед `exit 0`:
  ```sh
  sleep 8
  /usr/bin/singbox-tproxy-up
  ```
  (скрипт установки добавляет эти строки сам, если их ещё нет)

Нужны пакеты: **`kmod-nft-tproxy`**, **`kmod-nf-tproxy`**. Не подключайте nft-файл к **fw4** как include — отдельная таблица.

После reboot: `cat /tmp/singbox-tproxy.log` должен содержать **OK**.

## Список (`domains.list`)

Одна запись в строке. **`#`** — комментарий. Домен — суффикс; **`*.example.com`** ≡ **`example.com`**. CIDR — в **`ip_cidr`**.

## Удаление UI / TPROXY

```sh
rm -f /usr/bin/singbox-apply-domains /usr/bin/singbox-tproxy-up \
  /etc/singbox-tproxy.nft /www/cgi-bin/singbox-domains
nft delete table inet singbox_tproxy 2>/dev/null
# убери строки sleep/singbox-tproxy-up из /etc/rc.local
```

## Если сплит не работает

`sing-box` запущен; есть **nft tproxy**; **`ip rule`** с **fwmark**; table 100 — **`local default dev lo`**; в inbound — **sniff** + **sniff_override_destination**.
