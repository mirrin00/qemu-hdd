## Сборка изображения
```bash
docker build -t femu-test:1.0.0 .
```

## Запуск изображения
```bash
docker run -it --rm --privileged --device=/dev/kvm femu-test:1.0.0 ./run-blackbox.sh
```

Данные для входа:
```
login: user
password: user
```

**`nvme0n1` - диск, добавленный FEMU**
