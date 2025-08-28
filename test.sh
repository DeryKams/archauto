#!/bin/bash

if [ -f "/etc/resolv.conf" ]; then 

echo "Файл найден"
echo "
nameserver 8.8.8.8
nameserver 1.1.1.1
324
" > /etc/resolv.conf

else 
echo "Файл  не найден"

fi