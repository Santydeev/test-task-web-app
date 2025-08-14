# Web Application на Go с GitLab CI/CD

Полнофункциональное веб-приложение на Go с использованием Gin фреймворка, включающее полную DevOps инфраструктуру с GitLab CI/CD, мониторингом, логированием и автоматическим развертыванием.

## 🏗️ Архитектура проекта

```
test-task-web-app/
├── main.go                 # Основное приложение
├── main_test.go           # Тесты приложения
├── go.mod                 # Зависимости Go
├── go.sum                 # Хеши зависимостей
├── Dockerfile             # Multi-stage Docker образ
├── docker-compose.yml     # Полная инфраструктура
├── .gitlab-ci.yml         # GitLab CI/CD пайплайн
├── env.example            # Пример переменных окружения
├── scripts/
│   └── deploy.sh          # Скрипт развертывания
├── monitoring/
│   ├── prometheus.yml     # Конфигурация Prometheus
│   ├── loki-config.yml    # Конфигурация Loki
│   ├── promtail-config.yml # Конфигурация Promtail
│   └── grafana/
│       └── provisioning/  # Дашборды Grafana
├── infrastructure/
│   ├── nginx/             # Конфигурация Nginx
│   └── registry/          # Container Registry
└── docs/                  # Документация
```

## 🚀 Быстрый запуск

### Требования
- Docker 20.10+
- Docker Compose 2.0+
- GitLab Runner (для CI/CD)
- Минимум 8GB RAM
- 20GB свободного места

### 1. Клонирование и запуск
```bash
git clone https://gitlab.com/test-task-mitsina/test-task-web-app.git
cd test-task-web-app
./scripts/deploy.sh
```

### 2. Доступ к сервисам
После запуска будут доступны:
- **Веб-приложение**: http://localhost
- **GitLab Container Registry**: registry.gitlab.com/test-task-mitsina/test-task-web-app
- **Grafana**: http://localhost:3000 (admin/admin123)
- **Prometheus**: http://localhost:9090

## 📋 Функционал приложения

### REST API Endpoints
- `GET /health` - Health check приложения
- `GET /metrics` - Метрики Prometheus
- `GET /api/users` - Получение списка пользователей
- `POST /api/users` - Создание нового пользователя

### База данных
- **PostgreSQL** с автоматической инициализацией
- Автоматическое создание таблиц
- Тестовые данные при первом запуске

## 🏭 GitLab CI/CD Pipeline

### Стадии пайплайна
1. **validate** - Валидация кода (go vet, go fmt)
2. **test** - Запуск тестов с покрытием
3. **build** - Сборка Docker образа в GitLab Container Registry
4. **security** - Сканирование уязвимостей (Trivy + SAST)
5. **deploy-staging** - Развертывание в staging (manual)
6. **deploy-production** - Развертывание в production (manual)

### Особенности GitLab CI/CD
- **GitLab Container Registry** для хранения образов
- **SAST** для статического анализа кода
- **Dependency Scanning** для проверки зависимостей
- **Container Scanning** для сканирования образов
- **Кэширование** для ускорения сборки
- **Артефакты** тестового покрытия и отчетов безопасности

### Переменные окружения GitLab
Настройте следующие переменные в Settings > CI/CD > Variables:

#### Обязательные переменные
- `STAGING_SSH_PRIVATE_KEY` - SSH ключ для staging сервера
- `STAGING_HOST` - Хост staging сервера
- `STAGING_USER` - Пользователь для staging
- `STAGING_DB_HOST` - Хост БД для staging
- `STAGING_DB_PASSWORD` - Пароль БД для staging

- `PRODUCTION_SSH_PRIVATE_KEY` - SSH ключ для production сервера
- `PRODUCTION_HOST` - Хост production сервера
- `PRODUCTION_USER` - Пользователь для production
- `PRODUCTION_DB_HOST` - Хост БД для production
- `PRODUCTION_DB_PASSWORD` - Пароль БД для production

## 📊 Мониторинг и логирование

### Дашборды Grafana
- **Метрики приложения**: HTTP запросы, длительность, ошибки
- **Системные метрики**: CPU, RAM, диск, сеть
- **Метрики контейнеров**: использование ресурсов
- **Логи приложения**: уровни DEBUG, WARN, ERROR

### Prometheus метрики
- `http_requests_total` - Общее количество запросов
- `http_request_duration_seconds` - Длительность запросов
- `go_goroutines` - Количество горутин
- `go_memstats_*` - Статистика памяти

## 🔄 Управление развертыванием

### Команды скрипта deploy.sh
```bash
./scripts/deploy.sh deploy    # Развертывание
./scripts/deploy.sh stop      # Остановка
./scripts/deploy.sh restart   # Перезапуск
./scripts/deploy.sh logs      # Просмотр логов
./scripts/deploy.sh status    # Статус сервисов
./scripts/deploy.sh clean     # Полная очистка
```

### GitLab CI/CD команды
```bash
# Запуск пайплайна вручную
git push origin main

# Развертывание в staging
# Перейдите в GitLab UI > Pipelines > Manual actions > deploy-staging

# Развертывание в production
# Перейдите в GitLab UI > Pipelines > Manual actions > deploy-production
```

## 🧪 Тестирование

### Запуск тестов локально
```bash
# Локально
go test -v -race -coverprofile=coverage.out ./...

# В Docker
docker-compose run --rm webapp go test -v ./...
```

### Покрытие кода
```bash
go tool cover -html=coverage.out -o coverage.html
```

## 🔍 GitLab Features

### Container Registry
```bash
# Логин в GitLab Container Registry
docker login registry.gitlab.com

# Pull образа
docker pull registry.gitlab.com/test-task-mitsina/test-task-web-app:latest

# Push образа
docker push registry.gitlab.com/test-task-mitsina/test-task-web-app:latest
```

### Security Dashboard
- **SAST** - Статический анализ кода
- **Dependency Scanning** - Проверка зависимостей
- **Container Scanning** - Сканирование Docker образов
- **Secret Detection** - Поиск секретов в коде

### Merge Requests
- Автоматический запуск пайплайна
- Проверка тестов и безопасности
- Code Quality отчеты
- Coverage отчеты

## 🔐 Безопасность

### Рекомендации для production
1. **Настройте переменные** в GitLab CI/CD Variables
2. **Настройте SSL/TLS** сертификаты
3. **Ограничьте доступ** к проекту
4. **Настройте firewall** правила
5. **Регулярно обновляйте** образы
6. **Используйте Protected branches** для main

### GitLab Security Features
- **Protected Variables** для чувствительных данных
- **Protected Branches** для критических веток
- **Push Rules** для контроля коммитов
- **Security Policies** для автоматических проверок

## 🚀 Развертывание в облаке

### Подготовка серверов
1. **Настройте staging и production сервера**
2. **Установите Docker на серверах**
3. **Настройте SSH доступ**
4. **Добавьте SSH ключи в GitLab Variables**

### Автоматическое развертывание
1. Push в main ветку запускает пайплайн
2. После успешной сборки и тестов доступно manual развертывание
3. Staging развертывание для тестирования
4. Production развертывание после подтверждения

## 📞 Поддержка

### GitLab CI/CD отладка
```bash
# Просмотр логов пайплайна в GitLab UI
# Pipelines > [Pipeline ID] > Jobs > [Job Name]

# Локальная отладка с gitlab-runner
gitlab-runner exec docker test

# Проверка .gitlab-ci.yml
gitlab-ci-multi-runner verify
```

### Полезные команды
```bash
# Мониторинг ресурсов
docker stats

# Очистка неиспользуемых ресурсов
docker system prune -a

# Просмотр образов в registry
docker images | grep registry.gitlab.com
```

## 📄 Лицензия

MIT License - см. файл LICENSE для деталей.

---

**Репозиторий**: https://gitlab.com/test-task-mitsina/test-task-web-app  
**Container Registry**: registry.gitlab.com/test-task-mitsina/test-task-web-app  
**Версия**: 1.0.0  
**Дата**: 2024