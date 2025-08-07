# Web Application на Go с Gin

Простое веб-приложение на Go с использованием Gin фреймворка, PostgreSQL базы данных, логированием и метриками Prometheus.

## Функционал

- **REST API** с endpoints:
  - `GET /health` - health check (статус приложения)
  - `GET /metrics` - метрики для Prometheus
  - `GET /api/users` - получить список пользователей
  - `POST /api/users` - создать пользователя

- **База данных**: PostgreSQL с автоматической инициализацией таблиц
- **Логирование**: Структурированное логирование с уровнями (INFO, DEBUG, ERROR)
- **Метрики**: Prometheus метрики для мониторинга

## Быстрый запуск с Docker Compose

1. Клонируйте репозиторий:
```bash
git clone <repository-url>
cd -test-task-web-app
```

2. Запустите приложение:
```bash
docker-compose up -d
```

3. Приложение будет доступно по адресу: http://localhost:8080

## Локальный запуск

### Требования
- Go 1.21+
- PostgreSQL

### Настройка базы данных
1. Установите PostgreSQL
2. Создайте базу данных:
```sql
CREATE DATABASE webapp;
```

### Переменные окружения
Создайте файл `.env` или установите переменные окружения:

```bash
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=password
DB_NAME=webapp
LOG_LEVEL=INFO
PORT=8080
```

### Запуск
```bash
# Установка зависимостей
go mod download

# Запуск приложения
go run main.go
```

## API Endpoints

### Health Check
```bash
GET /health
```

**Ответ:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T12:00:00Z",
  "service": "web-app"
}
```

### Получить список пользователей
```bash
GET /api/users
```

**Ответ:**
```json
{
  "users": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "created_at": "2024-01-01T12:00:00Z"
    }
  ]
}
```

### Создать пользователя
```bash
POST /api/users
Content-Type: application/json

{
  "name": "New User",
  "email": "newuser@example.com"
}
```

**Ответ:**
```json
{
  "user": {
    "id": 4,
    "name": "New User",
    "email": "newuser@example.com",
    "created_at": "2024-01-01T12:00:00Z"
  }
}
```

### Метрики Prometheus
```bash
GET /metrics
```

Доступные метрики:
- `gin_requests_total` - общее количество запросов
- `gin_request_duration_seconds` - длительность запросов
- `gin_requests_in_flight` - количество активных запросов

## Логирование

Приложение использует структурированное логирование с уровнями:
- **INFO** - основная информация о работе приложения
- **DEBUG** - детальная отладочная информация
- **ERROR** - ошибки и исключения

Уровень логирования можно настроить через переменную окружения `LOG_LEVEL`.

## Структура проекта

```
.
├── main.go              # Основной файл приложения
├── go.mod               # Go модуль с зависимостями
├── go.sum               # Хеши зависимостей
├── Dockerfile           # Docker образ
├── docker-compose.yml   # Docker Compose конфигурация
└── README.md           # Документация
```

## Тестирование API

### С помощью curl

```bash
# Health check
curl http://localhost:8080/health

# Получить пользователей
curl http://localhost:8080/api/users

# Создать пользователя
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Test User", "email": "test@example.com"}'

# Получить метрики
curl http://localhost:8080/metrics
```

## Мониторинг

Приложение экспортирует метрики в формате Prometheus на endpoint `/metrics`. Эти метрики можно использовать для:

- Мониторинга производительности
- Алертинга
- Визуализации в Grafana

## Разработка

### Добавление новых endpoints

1. Добавьте новый обработчик в `main.go`
2. Зарегистрируйте маршрут в функции `setupRouter()`

### Изменение модели данных

1. Обновите структуру `User` в `main.go`
2. Измените SQL запросы в соответствующих функциях
3. Обновите миграцию базы данных

## Лицензия

MIT
