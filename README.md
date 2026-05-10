# TR30 — Amnezia / Xray, сплит-туннель (sing-box, OpenWrt)

## 1. Заполни реквизиты подключения к VPS

В репозитории открой файл **`openwrt-luci-singbox-domains/root/etc/sing-box/config.json`** и подставь свои данные из Amnezia (или с VPS) **вместо заглушек** в outbound с **`"tag": "proxy"`** (тип **`vless`**):

| Поле в JSON | Что вставить |
|-------------|----------------|
| **`server`** | IP или домен VPS (сейчас строка **`REPLACE_VPS_HOST_OR_IP`**) |
| **`server_port`** | Порт на VPS (часто **443**) |
| **`uuid`** | UUID клиента (сейчас **`00000000-0000-4000-8000-000000000001`**) |
| **`tls.server_name`** | SNI для Reality (сейчас **`REPLACE_REALITY_SERVER_NAME`**) |
| **`tls.reality.public_key`** | Публичный ключ Reality в Base64 (в шаблоне стоит техническая заглушка — **замени на ключ с сервера**) |
| **`tls.reality.short_id`** | Short ID Reality, hex (в шаблоне заглушка — **замени на свой**) |

Поле **`flow`**: для VLESS + Vision обычно **`xtls-rprx-vision`** (как в Amnezia).  
Вход **`tproxy`**: порт **`listen_port`** (**12345**) должен совпадать с **nft TPROXY** на роутере; блоки **`sniff`** и **`sniff_override_destination`** для сплита по доменам не убирай.

Первый деплой **перезапишет** на роутере **`/etc/sing-box/config.json`** из этого файла. Если на роутере уже был свой конфиг — сделай копию или перенеси реквизиты в шаблон в репозитории до шага 2.

---

## 2. Запусти скрипт установки с компьютера

Из каталога **`openwrt-luci-singbox-domains`** (внутри клонированного репозитория):

```sh
cd openwrt-luci-singbox-domains
chmod +x scripts/install-to-router.sh
ROUTER=root@192.168.1.1 ./scripts/install-to-router.sh
```

На Windows (PowerShell), из того же каталога: **`.\scripts\install-to-router.ps1`**  
(нужен **OpenSSH Client**). При другом логине/IP: **`ROUTER=root@192.168.1.1`** перед `./scripts/...` или **`$env:ROUTER`** в PowerShell.

Скрипт копирует на роутер **`root/etc`** (в т.ч. **`config.json`**, **`domains.list`**), **`root/usr`**, **`root/www`**.

---

## 3. Зайди на роутер по SSH и выполни

Подставь свой пакет sing-box, если имя другое (`opkg list-installed | grep sing`).

```sh
ssh root@192.168.1.1

opkg update
opkg install jq
opkg install sing-box

chmod +x /usr/bin/singbox-apply-domains /www/cgi-bin/singbox-domains
sing-box check -c /etc/sing-box/config.json
/usr/bin/singbox-apply-domains
/etc/init.d/sing-box enable
/etc/init.d/sing-box restart
rm -f /tmp/luci-indexcache
/etc/init.d/uhttpd restart
```

Если **`sing-box`** в `opkg` нет для твоей платформы — поставь свой пакет или бинарник, затем те же команды, начиная с **`chmod`**.

Редактор списка доменов: **`http://IP-роутера/cgi-bin/singbox-domains`**.

Дальше на роутере нужны **TPROXY**, **`ip rule` / table 100** и т.д. — см. **`openwrt-luci-singbox-domains/INSTALL.md`**.
