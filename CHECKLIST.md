# Чек-лист: AnyType на ZimaOS

Логин GitHub: **numback** | IP: **192.168.10.95**

---

## ✓ Шаг 1: Fork

Откройте https://github.com/anyproto/any-sync-dockercompose → **Fork** → **Create fork**

Результат: `https://github.com/numback/any-sync-dockercompose`

---

## ✓ Шаг 2: Загрузите файлы

В вашем форке: **Add file** → **Upload files**

Загрузите **по одному** (или группами) следующие файлы из пакета `D:\Numback's\AI Tools\mimo\anytype-zimaos-deploy\`:

| Файл | Куда в репозитории | Commit message |
|------|-------------------|----------------|
| `Dockerfile` | корень | `Replace Dockerfile for ZimaOS` |
| `entrypoint.sh` | корень | `Add entrypoint script` |
| `supervisord.conf` | корень | `Add supervisord config` |
| `.env` | корень | `Add env config` |
| `.dockerignore` | корень | `Add .dockerignore` |
| `docker-generateconfig/` | корень (вся папка) | `Add config templates` |
| `.github/workflows/docker-build.yml` | в папку `.github/workflows/` | `Add build workflow` |

---

## ✓ Шаг 3: Запустите сборку

1. Перейдите: https://github.com/numback/any-sync-dockercompose/actions
2. Если Asked — нажмите **"I understand my workflows, go ahead and enable them"**
3. Нажмите **"Run workflow"** → **Run workflow**
4. Ждите ~10 минут до зелёной галочки

Результат: образ `ghcr.io/numback/any-sync-dockercompose:latest`

---

## ✓ Шаг 4: Установите в ZimaOS

1. Откройте `http://192.168.10.95` → **Установщик приложений**

2. Заполните:
   - Образ Docker: `ghcr.io/numback/any-sync-dockercompose:latest`
   - Заголовок: `AnyType Sync`
   - Web UI: `http://192.168.10.95:9001/`
   - Сеть: `bridge`

3. Порты (нажимайте "+ Добавить" для каждого):
   ```
   1001/tcp  1002/tcp  1003/tcp  1004/tcp  1005/tcp  1006/tcp
   1011/udp  1012/udp  1013/udp  1014/udp  1015/udp  1016/udp
   9000/tcp  9001/tcp  27001/tcp  6379/tcp
   ```

4. Том:
   ```
   Внутри: /data    →    Вне: /DATA/AppData/anytype
   ```

5. **Установить** → ждите 2-3 минуты

---

## ✓ Шаг 5: Скачайте client.yml

1. ZimaOS → Файловый менеджер
2. Перейдите: `/DATA/AppData/anytype/etc/`
3. Скачайте `client.yml` на компьютер

---

## ✓ Шаг 6: Настройте Anytype

1. Откройте Anytype → **выйдите** из аккаунта
2. ⚙ → **Network** → **Self-hosted**
3. Загрузите `client.yml`
4. **Создайте новый аккаунт** (не старый!)

---

## ✓ Готово!

Данные синхронизируются через ваш Beelink. Подключите телефон/второй компьютер тем же способом (загрузите client.yml + войдите в тот же аккаунт).
