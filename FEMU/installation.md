# Установка
***!!! Рекомендуется запускать FEMU на физической машине, а не внутри VM !!!***

## Сборка FEMU

1. **Клонирование репозитория**:
```bash
git clone https://github.com/MoatLab/FEMU.git
cd FEMU
```

2. **Создание директории для сборки**:
```bash
mkdir build-femu
cd build-femu
```

3. **Подготовка к сборке**:
```bash
# копирование и запуск скрипта, который скопирует остальные скрипты
cp ../femu-scripts/femu-copy-scripts.sh .
./femu-copy-scripts.sh .

# автоматическая установка зависимостей (только Ubuntu/Debian)
sudo ./pkgdep.sh
```
*Список зависимостей для ручной установки:*
- `gcc pkg-config git libglib2.0-dev libfdt-dev libpixman-1-dev zlib1g-dev libdw-dev`
- `libaio-dev libslirp-dev`
- `libnuma-dev`
- `ninja-build`

4. **Сборка FEMU**:
```bash
./femu-compile.sh
```
*Бинарный файл FEMU будет создан как:* `./qemu-system-x86_64`


5. **Проверка сборки**:
```bash
# ожидаемый вывод: name "femu", bus PCI, desc "FEMU Non-Volatile Memory Express"
./qemu-system-x86_64 -device help | grep femu

# должно вывести возможные параметры FEMU
./qemu-system-x86_64 -device femu,help

# должно вывести версию QEMU
./qemu-system-x86_64 --version
```

## Запуск FEMU

1. **Установка ISO гостевой системы**

*Если уже есть ISO какой-то linux-системы, то можно использовать его, если нет - то ниже инструкции для загрузки Ubuntu Server 24.04*
```bash
# download Ubuntu Server ISO
# if the link no longer works, visit http://releases.ubuntu.com to download the correct version of ISO image
wget -O <your-iso-name.iso> http://releases.ubuntu.com/24.04/ubuntu-24.04.3-live-server-amd64.iso
```

2. **Создание диска под FEMU**

*Диск должен быть в директории `~/images/` (эту директорию используют скрипты FEMU, например `run-blackbox.sh`; если не получится использовать такую директорию - можно поменять пути в этих скриптах)*
```bash
# все еще в той директории, где собирали FEMU

# создаем требуемую директорию
mkdir -p ~/images

# создаем диск (название тоже должно быть определенным для работы скриптов)
./qemu-img create -f qcow2 ~/images/u20s.qcow2 80G

# устанавливаем на диск ОС
./qemu-system-x86_64 -cdrom <your-iso-name.iso> -hda ~/images/u20s.qcow2 -boot d -net nic -net user -m 8192 -localtime -smp 8 -cpu host -enable-kvm
```

3. **Настройка VM**

***Внутри гостевой ОС*** *меняем `/etc/default/grub`*
```bash
sudo nano /etc/default/grub
```

*Добавляем следующие строки:*
```
GRUB_CMDLINE_LINUX="ip=dhcp console=ttyS0,115200 console=tty console=ttyS0"
GRUB_TERMINAL=serial
GRUB_SERIAL_COMMAND="serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1"
```

*Обновляем GRUB и выходим из VM:*
```bash
sudo update-grub
sudo shutdown now
```

4. **Запуск FEMU**
```bash
./run-blackbox.sh
```

5. **Проверка наличия SSD в гостевой ОС**
```bash
lsblk -d -o name,size,rota
```
*Должна быть запись с диском, у которого:*
- *`SIZE` равен `12G` (такой размер указан по умолчанию в `run-blackbox.sh`)* 
- *`ROTA` равен `0` (от `ROTATE`, диск не вращается - значит SSD)*
