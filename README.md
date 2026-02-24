# qemu-hdd
## Сборка QEMU
Необходимо склонировать репозиторий QEMU версии 9.1.0
```
git clone --branch v9.1.0 git@github.com:qemu/qemu.git
cd qemu
```

И применить патч
```
git am ../QEMU_patches/0000-QEMU-test-disk.patch
```

Затем - собрать QEMU
```
mkdir build
cd build

../configure --target-list=x86_64-softmmu --enable-slirp --enable-debug 
make -j$(nproc)
```

Проверка того, что QEMU успешно собран, а модель диска есть в перечне устройств
```
# должно вывести версию QEMU
./qemu-system-x86_64 --version

# должно вывести запись об устройстве
./qemu-system-x86_64 -device help | grep test_disk
```

Теперь необходимо создать диск с гостевой операционной системой
```
# установка образа ОС
wget http://releases.ubuntu.com/24.04/ubuntu-24.04.3-live-server-amd64.iso

# создание образа диска
./qemu-img create -f qcow2 os.qcow2 20G

# установка гостевой ОС
./qemu-system-x86_64 -cdrom ubuntu-24.04.3-live-server-amd64.iso -hda os.qcow2 -boot d -net nic -net user -m 8192 -smp 8 -cpu host -enable-kvm
```

После того, как гостевая система была установлена на образ диска QEMU - виртуальную машину можно выключать


Также необходимо создать образ диска для модели
```
./qemu-img create -f qcow2 test.qcow2 1G
```

## Сборка сервера
```
# в корне qemu
cd contrib/test_disk-server

mkdir build
cd build

cmake ..
make
```

Собранные таргеты:
- `qemu_server` - сервер
- `qemu_server_change_parameters` - утилита для изменения параметров сервера в рантайме
- `server_toolkit_py.cpython-314-x86_64-linux-gnu.so` - модуль с питоновскими биндингами

Помимо сервера на C++ также написан сервер на python с использованием биндингов (`server.py`)

## Запуск сервера и QEMU
Сперва необходимо запустить сервер
```
./contib/test_disk-server/build/qemu_server
```

Затем запускается QEMU
```
./build/qemu-system-x86_64 \ 
-net nic -net user \
-m 8192 -smp 8 \
-cpu host,-kvmclock -rtc clock=vm -enable-kvm \
-device virtio-scsi-pci,id=scsi0 \
-drive file=build/os.qcow2,format=qcow2,if=none,id=drive_os \
-device scsi-hd,drive=drive_os,bus=scsi0.0,bootindex=0 \
-drive file=build/test.qcow2,format=qcow2,if=none,id=drive_test \
-device test_disk,drive=drive_test,bus=scsi0.0,disk-id=0
```

## Использование диска в гостевой ОС
dd
```
# чтение
dd if=/dev/sdb of=/dev/null bs=512 iflag=direct

# запись
dd if=/dev/sda of=/dev/sdb bs=512 count=2048 oflag=direct
```

fio
```
apt install fio

# чтение
fio --name=test_read --filename=/dev/sdb --rw=read --bs=512 --direct=1 --ioengine=libaio --iodepth=1 --runtime=1000 --time_based --continue_on_error=all --status-interval=1

# запись
fio --name=test_write --filename=/dev/sdb --rw=write --bs=512 --direct=1 --ioengine=libaio --iodepth=1 --runtime=1000 --time_based --continue_on_error=all --status-interval=1

# проверка корректности записи и чтения
fio --name=stress_test \
    --filename=/dev/sdb \
    --rw=randrw \
    --rwmixread=70 \
    --bsrange=512-64k \
    --direct=1 \
    --iodepth=4 \
    --size=50M \
    --verify=md5 \
    --do_verify=1 \
    --verify_dump=1 \
    --verify_fatal=1
```