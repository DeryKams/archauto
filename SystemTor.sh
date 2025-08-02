sudo pacman -Syu tor nyx torsocks
sudo systemctl enable --now tor.service
systemctl status tor.service
sudo nano /etc/tor/torrc
#Раскоментировать
ControlPort 9051
CookieAuthentication 1
#Добавить строки для работы в группе
CookieAuthFile /var/lib/tor/control_auth_cookie
CookieAuthFileGroupReadable 1
DataDirectoryGroupReadable 1
#Добавляем своего пользователя в группу tor
sudo usermod -aG tor $USER
newgrp tor
#Перезапускаеи службу
sudo systemctl restart tor
#Проверяем порт по-умолчанию
ss -nlt | grep 9050
#tor для отдельных приложений
torsocks curl https://check.torproject.org
#Плагин для мостов
sudo pacman -S obfs4proxy
#Добавляем использование мостов
sudo nano /etc/tor/torrc
#Также рекомендуется подключить транспорт obfs4. Включаем маскировку трафика
UseBridges 1
ClientTransportPlugin obfs4 exec /usr/bin/obfs4proxy

#Необходимо получить мосты и вставить их в таком виде
Bridge obfs4 IP1:PORT1 FINGERPRINT1 CERTIFICATE1 IAT_MODE=0
Bridge obfs4 IP2:PORT2 FINGERPRINT2 CERTIFICATE2 IAT_MODE=0
Bridge obfs4 IP3:PORT3 FINGERPRINT3 CERTIFICATE3 IAT_MODE=0

#Перезапускаем службу
sudo systemctl restart tor
#Проверка работы
curl --socks5-hostname localhost:9050 https://check.torproject.org
#Запускаем браузер
chromium --proxy-server="socks5://127.0.0.1:9050"
#Для ТЕКСТОВЫХ команд (curl, wget, git и т.д.): Используйте `torsocks`:
torsocks ваша_команда


#получение портов через телеграм
#!/bin/bash
# Получаем мосты через бота
bridges=$(curl -s "https://api.telegram.org/botВАШ_API_TOKEN/getUpdates" | grep -oP 'obfs4 [^"]+')

# Обновляем torrc
sudo sed -i '/UseBridges 1/d; /Bridge /d' /etc/tor/torrc
echo "UseBridges 1" | sudo tee -a /etc/tor/torrc
for bridge in $bridges; do
  echo "Bridge $bridge" | sudo tee -a /etc/tor/torrc
done
sudo systemctl restart tor.service
Готовый пакет: Onion Bridges Updater

Установка:
bash

git clone https://github.com/ValdikSS/tor-bridges-updater
cd tor-bridges-updater
sudo ./install.sh
