
#объявляем функцию для включения служб
enable_service(){

local service_name="$1"
#$1 - это первый аргумент, который передается функции
# local - объявляем переменную, которая будет локально внутри данной функции. К примеру, чтобы она не перезаписывала глобальные 

if systemctl enable --now "$service_name"; then
echo "Service $service_name enabled and started successfully."

if systemctl is-active --quiet "$service_name"; then
# systemctl is-active - специально созданная команда для проверки статуса службы
# --quiet - означает, что вывод будет без лишней информации, только код возврата
    echo "Service $service_name is running."
else
    echo "Service $service_name is not running after enabling."
            journalctl -n 5 -u "$service_name" --no-pager
fi      
else
echo "Failed to enable or start service $service_name. It may already be running or not exist."
 journalctl -n 10 -u "$service_name" --no-pager
fi


}
# проверяем статусы служб
#Объявляем массив для служб
# -a - объявляем, что это массив
# -r - объявляем, что массив является неизменяемым, то есть только для чтения
declare -a LIST_SERVICE_CHECK=(
 "reflector.service"
    "reflector.timer"
    "fail2ban.service"
    "nohang-desktop.service"
    "ananicy.service"
    "irqbalance.service"
)

for item in "${LIST_SERVICE_CHECK[@]}"; do 
#for - это цикл, который перебирает элементы массива
# item - переменная, которую мы задали конкретно для данного цикла. Туда "кладется" каждый элемент массива по очереди
# "" - нужны для того, чтобы службы в которых присутствуют пробелы были восприняты, как единое целое, а не ка кнесколько служб
# [@] - квадрытные скобки нужны для обращения к элементам массива, а знак @ - для обращения ко всем элементам массива
# если просто объявить $LIST_SERVICE_CHECK, то bash возьмет только первый элемент массива, а не все
# если использовать [*], то будет взят весь массив, как единое целое, то есть все элементы массива будут восприниматься как одна строка
enable_service "$item"
# enable_service - функция, которую мы ранее определили и которая берет элемент item и выполняет операции
done
