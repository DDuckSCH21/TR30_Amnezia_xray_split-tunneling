# TR30 — Amnezia / Xray, сплит-туннель (sing-box, OpenWrt)

## 1. Заполни реквизиты подключения к VPS

В репозитории открой файл **`openwrt-luci-singbox-domains/root/etc/sing-box/config.json`** и подставь свои данные из Amnezia (или с VPS) **вместо заглушек** в outbound с **`"tag": "proxy"`** (тип **`vless`**):

| Поле в JSON | Что вставить |
|-------------|----------------|
| **`server`** | IP или домен VPS (сейчас строка **`REPLACE_VPS_HOST_OR_IP`**) |
| **`server_port`** | Порт на VPS (часто **443**) |
| **`uuid`** | UUID клиента (сейчас **`00000000-0000-4000-8000-000000000001`**) |
| **`tls.server_name`** | SNI для Reality (сейчас **`REPLACE_REALITY_SERVER_NAME`**) |
| **`tls.reality.public_key`** | Публичный ключ Reality в Base64 (в шаблоне — техническая заглушка, **замени**) |
| **`tls.reality.short_id`** | Short ID Reality, hex (**замени на свой**) |

Поле **`flow`**: обычно **`xtls-rprx-vision`**.  
Вход **`tproxy`**: порт **`listen_port`** (**12345**) = порт в **`/etc/singbox-tproxy.nft`**; не убирай **`sniff`** и **`sniff_override_destination`**.

Первый деплой **перезапишет** на роутере **`/etc/sing-box/config.json`**.

---

## 2. Запусти скрипт установки с компьютера

```sh
cd openwrt-luci-singbox-domains
chmod +x scripts/install-to-router.sh
ROUTER=root@192.168.1.1 ./scripts/install-to-router.sh
```

Windows: **`.\scripts\install-to-router.ps1`**.

Копируются **`config.json`**, **`domains.list`**, UI, **`singbox-tproxy.nft`**, **`singbox-tproxy-up`**; в **`/etc/rc.local`** добавляется автозапуск TPROXY (если ещё нет).

---

## 3. Зайди на роутер по SSH и выполни

```sh
ssh root@192.168.1.1

opkg update
opkg install jq kmod-nft-tproxy kmod-nf-tproxy
opkg install sing-box

chmod +x /usr/bin/singbox-apply-domains /usr/bin/singbox-tproxy-up /www/cgi-bin/singbox-domains
sing-box check -c /etc/sing-box/config.json
/usr/bin/singbox-apply-domains
/etc/init.d/sing-box enable
/etc/init.d/sing-box restart
/usr/bin/singbox-tproxy-up
rm -f /tmp/luci-indexcache
/etc/init.d/uhttpd restart
```

Проверка TPROXY: `ip rule | grep fwmark`, `nft list table inet singbox_tproxy | grep tproxy`, `cat /tmp/singbox-tproxy.log`.

Редактор списка: **`http://IP-роутера/cgi-bin/singbox-domains`**.

Подробности: **`openwrt-luci-singbox-domains/INSTALL.md`**.
