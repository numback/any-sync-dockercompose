# AnyType Self-Hosted на ZimaOS — Подробная инструкция

Ваш логин GitHub: **numback**
IP Beelink: **192.168.10.95**

---

## ЭТАП 1: Fork репозитория

1. Откройте в браузере: https://github.com/anyproto/any-sync-dockercompose
2. В правом верхнем углу нажмите кнопку **Fork**
3. В поле "Repository name" оставьте `any-sync-dockercompose` (или назовите как хотите)
4. Нажмите **Create fork**
5. Вы попадёте в вашу копию: `https://github.com/numback/any-sync-dockercompose`

---

## ЭТАП 2: Скачивание файлов из нашего пакета

На вашем компьютере откройте папку:
```
D:\Numback's\AI Tools\mimo\anytype-zimaos-deploy\
```

В ней находятся все файлы, которые нужно загрузить в ваш форк.

---

## ЭТАП 3: Загрузка файлов в ваш форк

### Способ A: Через веб-интерфейс GitHub (проще всего)

**3.1. Загрузите Dockerfile:**

1. В вашем форке перейдите в корень репозитория
2. Нажмите **Add file** → **Upload files**
3. Перетащите файл `Dockerfile` из пакета (или нажмите "choose your files" и выберите его)
4. В поле "Commit changes" напишите: `Replace Dockerfile for ZimaOS all-in-one build`
5. Нажмите **Commit changes**

**3.2. Загрузите entrypoint.sh:**

1. Снова **Add file** → **Upload files**
2. Перетащите файл `entrypoint.sh`
3. Commit message: `Add entrypoint with config generation`
4. **Commit changes**

**3.3. Загрузите supervisord.conf:**

1. **Add file** → **Upload files**
2. Перетащите файл `supervisord.conf`
3. Commit message: `Add supervisord for multi-process management`
4. **Commit changes**

**3.4. Загрузите .env:**

1. **Add file** → **Upload files**
2. Перетащите файл `.env`
3. Commit message: `Add environment config for Beelink Mini S`
4. **Commit changes**

**3.5. Загрузите .dockerignore:**

1. **Add file** → **Upload files**
2. Перетащите файл `.dockerignore`
4. Commit message: `Add .dockerignore`
5. **Commit changes**

**3.6. Загрузите папку docker-generateconfig:**

1. **Add file** → **Upload files**
2. Перетащите **всю папку** `docker-generateconfig` (вместе с подпапкой `etc/`)
3. Убедитесь, что структура выглядит так:
   ```
   docker-generateconfig/
   ├── setListenIp.py
   └── etc/
       ├── aws-credentials
       ├── common.yml
       ├── consensusnode.yml
       ├── coordinator.yml
       ├── filenode.yml
       ├── node-1.yml
       ├── node-2.yml
       └── node-3.yml
   ```
4. Commit message: `Add config generation templates`
5. **Commit changes**

**3.7. Загрузите файл GitHub Actions:**

Сначала создайте папку `.github/workflows` в вашем форке:

1. В адресной строке браузера перейдите по адресу (заменив numback на ваш логин, если отличается):
   ```
   https://github.com/numback/any-sync-dockercompose/new/main?filename=.github/workflows/docker-build.yml
   ```
2. Или вручную:
   - Нажмите **Add file** → **Create new file**
   - В поле имени файла напишите: `.github/workflows/docker-build.yml`
   - Скопируйте содержимое файла `.github/workflows/docker-build.yml` из пакета и вставьте в текстовое поле
3. Commit message: `Add GitHub Actions workflow for Docker build`
4. **Commit changes**

---

## ЭТАП 4: Проверка файлов

Убедитесь, что в вашем форке `https://github.com/numback/any-sync-dockercompose` есть все файлы:

```
.github/
  workflows/
    docker-build.yml
docker-generateconfig/
  etc/
    aws-credentials
    common.yml
    consensusnode.yml
    coordinator.yml
    filenode.yml
    node-1.yml
    node-2.yml
    node-3.yml
  setListenIp.py
.env
.dockerignore
Dockerfile
entrypoint.sh
supervisord.conf
```

---

## ЭТАП 5: Запуск сборки образа

1. Перейдите в ваш форк: `https://github.com/numback/any-sync-dockercompose`
2. Нажмите вкладку **Actions** (в верхнем меню)
3. Если GitHub просит разрешение на Actions — нажмите **"I understand my workflows, go ahead and enable them"**
4. Workflow `Build and Push Docker Image` должен появиться в списке
5. Нажмите на него → **Run workflow** → **Run workflow**
6. Сборка начнётся. Нажмите на активный workflow чтобы видеть прогресс

**Что происходит при сборке:**
- Скачиваются официальные Docker-образы any-sync (coordinator, node, filenode, consensus, tools)
- Из них извлекаются бинарные файлы
- Устанавливаются MongoDB 7.0, Redis, MinIO
- Собирается финальный all-in-one образ
- Образ загружается в GitHub Container Registry (GHCR)

**Время сборки:** ~5-15 минут

**Когда сборка завершится:**
- Рядом с workflow появится **зелёная галочка** (✅)
- Образ будет доступен по адресу:
  ```
  ghcr.io/numback/any-sync-dockercompose:latest
  ```

---

## ЭТАП 6: Установка в ZimaOS

### 6.1. Откройте веб-интерфейс ZimaOS

В браузере перейдите: `http://192.168.10.95` (или тот адрес, который используете для ZimaOS)

### 6.2. Откройте установщик приложений

Найдите и откройте **Установщик приложений** (Docker-установщик). Вы увидите форму, как на скриншоте.

### 6.3. Заполните основные поля

| Поле | Значение |
|------|----------|
| **Образ Docker** | `ghcr.io/numback/any-sync-dockercompose:latest` |
| **Тер** | `latest` |
| **Заголовок** | `AnyType Sync` |
| **Web UI** | Выберите `http://` → в поле хоста: `192.168.10.95` → порт: `9001` → путь: `/` |
| **Сеть** | `bridge` |

### 6.4. Добавьте порты

Нажмите **+ Добавить** рядом с **Порты** и добавьте **каждый порт отдельно**:

| Порт | Протокол | Для чего |
|------|----------|----------|
| `1001` | TCP | Node 1 sync |
| `1002` | TCP | Node 2 sync |
| `1003` | TCP | Node 3 sync |
| `1004` | TCP | Coordinator sync |
| `1005` | TCP | Filenode sync |
| `1006` | TCP | Consensus sync |
| `1011` | UDP | Node 1 QUIC |
| `1012` | UDP | Node 2 QUIC |
| `1013` | UDP | Node 3 QUIC |
| `1014` | UDP | Coordinator QUIC |
| `1015` | UDP | Filenode QUIC |
| `1016` | UDP | Consensus QUIC |
| `9000` | TCP | MinIO API |
| `9001` | TCP | MinIO Console (Web UI) |
| `27001` | TCP | MongoDB |
| `6379` | TCP | Redis |

**Итого: 16 портов.** Добавляйте их по одному, нажимая "+ Добавить" каждый раз.

### 6.5. Добавьте том (хранилище данных)

Нажмите **+ Добавить** рядом с **Тома**:

| Внутренний путь (Container) | Внешний путь (Host) |
|-----------------------------|---------------------|
| `/data` | `/DATA/AppData/anytype` |

Это значит, что все данные (БД, файлы, конфиги) будут храниться на диске Beelink в папке `/DATA/AppData/anytype`.

### 6.6. Установите

Нажмите кнопку **Установить** внизу формы.

**Что происходит:**
1. ZimaOS скачивает Docker-образ (~1-2 ГБ)
2. Создаёт контейнер
3. `entrypoint.sh` запускается:
   - Стартует MongoDB для генерации конфигов
   - Создаёт криптогафические ключи сети (network ID, signing keys)
   - Генерирует конфигурационные файлы для всех сервисов
   - Останавливает MongoDB
   - Запускает supervisord, который стартует все 10 сервисов

**Ожидание:** 2-3 минуты для первого запуска.

---

## ЭТАП 7: Проверка работы

### 7.1. Проверьте статус контейнера

В ZimaOS → Приложения → найдите "AnyType Sync" → статус должен быть **"Работает"** (или "Running").

### 7.2. Откройте MinIO Console

В браузере: `http://192.168.10.95:9001`

- Логин: `minio_access_key`
- Пароль: `minio_secret_key_change_me` (или тот, что вы задали в .env)

### 7.3. Проверьте логи

В ZimaOS → Приложение → Логи. Должны быть строки:
```
[init] Configuration generated successfully!
[init] Starting all services...
```

---

## ЭТАП 8: Получение client.yml

Файл `client.yml` — это конфигурация вашей сети для клиента Anytype.

### Способ A: Через файловый менеджер ZimaOS

1. Откройте файловый менеджер ZimaOS
2. Перейдите в: `/DATA/AppData/anytype/etc/`
3. Найдите файл `client.yml`
4. Скопируйте/скачайте его на компьютер

### Способ B: Через SCP (если есть SSH)

```powershell
scp root@192.168.10.95:/DATA/AppData/anytype/etc/client.yml C:\Users\numba\Desktop\
```

---

## ЭТАП 9: Настройка клиента Anytype

### На компьютере (Windows):

1. Откройте Anytype
2. Если уже вошли в аккаунт — **выйдите** (Settings → Log out)
3. На экране приветствия нажмите **⚙** (шестерёнка) в правом верхнем углу
4. В выпадающем списке **Network** выберите **Self-hosted**
5. Нажмите **"Tap to provide your network configuration"** (или "Upload config")
6. Выберите файл `client.yml`, который скачали на шаге 8
7. Нажмите **Save**
8. **Создайте НОВЫЙ аккаунт** — введите имя, пароль, секретную фразу
   - **НЕ используйте** аккаунт из основной сети Anytype — это разные сети!

### На телефоне (iOS / Android):

1. Откройте Anytype
2. Выйдите из аккаунта
3. На экране входа → ⚙ → **Self-hosted**
4. Нажмите **"Tap to provide your network configuration"**
5. Загрузите `client.yml` (отправьте его себе на телефон через мессенджер/email)
6. Создайте новый аккаунт

### Подключение второго устройства:

На новом устройстве повторите те же шаги, но вместо создания нового аккаунта — **войдите** в созданный аккаунт (те же имя + пароль + секретная фраза). Данные синхронизируются через ваш self-hosted сервер.

---

## ЭТАП 10: Перенос данных из основной сети (опционально)

Если у вас уже есть данные в основной сети Anytype:

1. На **старом** аккаунте: Settings → Export → экспорт всех пространств
2. Выполните **ЭТАП 9** — создайте новый аккаунт в self-hosted сети
3. В **новом** аккаунте: Settings → Import → импортируйте экспортированные данные

---

## Управление сервером

| Действие | Как сделать |
|----------|-------------|
| Перезапуск | ZimaOS → Приложения → AnyType Sync → Перезапустить |
| Остановка | ZimaOS → Приложения → AnyType Sync → Остановить |
| Логи | ZimaOS → Приложения → AnyType Sync → Логи |
| Удаление | ZimaOS → Приложения → AnyType Sync → Удалить |
| Обновление образа | ZimaOS → Приложения → AnyType Sync → Изменить → обновить "Образ Docker" |

---

## Обновление образа

Когда выходит новая версия any-sync:

1. В вашем форке перейдите в **Actions**
2. Нажмите **"Run workflow"** — образ пересоберётся с последними версиями
3. На Beelink: остановите контейнер → измените образ (tags обновятся) → запустите

Или автоматически: при пуше изменений в `main` ветку Actions запустится сам.

---

## Решение проблем

**Контейнер падает сразу после запуска:**
- Откройте логи в ZimaOS
- Частая причина: порт уже занят другим приложением
- Проверьте, нет ли конфликтов портов (1001-1016, 27001, 6379, 9000, 9001)

**Клиент Anytype не подключается:**
- Убедитесь, что IP в .env (`EXTERNAL_LISTEN_HOSTS`) = `192.168.10.95`
- Убедитесь, что порты проброшены в настройках ZimaOS
- Проверьте, что используете **новый** аккаунт (не старый из основной сети)
- Проверьте, что `client.yml` загружен правильно

**Нет файла client.yml:**
- Проверьте логи — возможно, генерация конфигов не завершилась
- Попробуйте перезапустить контейнер

**MinIO Console недоступен:**
- Убедитесь, что порт 9001 проброшен
- Проверьте статус контейнера — MinIO может запускаться дольше остальных

---

## Требования

- Beelink Mini S с **минимум 8 ГБ RAM** (рекомендуется 16 ГБ)
- ZimaOS с доступом в интернет
- ~5 ГБ свободного места на диске
- Аккаунт GitHub (для форка и сборки)
