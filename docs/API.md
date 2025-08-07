# API Документация

## Обзор

Веб-приложение предоставляет REST API для управления пользователями с поддержкой мониторинга и метрик.

**Базовый URL**: `http://localhost` (через Nginx proxy)

## Аутентификация

В текущей версии API не требует аутентификации.

## Общие заголовки

Все ответы содержат следующие заголовки:
```
Content-Type: application/json
```

## Коды ответов

- `200` - Успешный запрос
- `201` - Ресурс создан
- `400` - Неверный запрос
- `404` - Ресурс не найден
- `409` - Конфликт (например, email уже существует)
- `500` - Внутренняя ошибка сервера

## Endpoints

### 1. Health Check

Проверка состояния приложения.

```http
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

**Пример:**
```bash
curl http://localhost/health
```

### 2. Метрики Prometheus

Экспорт метрик в формате Prometheus.

```http
GET /metrics
```

**Ответ:** Метрики в формате Prometheus

**Пример:**
```bash
curl http://localhost/metrics
```

**Основные метрики:**
- `http_requests_total` - Общее количество HTTP запросов
- `http_request_duration_seconds` - Длительность запросов
- `go_goroutines` - Количество горутин
- `go_memstats_*` - Статистика памяти

### 3. Получение списка пользователей

Получение всех пользователей в системе.

```http
GET /api/users
```

**Параметры запроса:**
- Нет

**Ответ:**
```json
{
  "users": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "created_at": "2024-01-01T12:00:00Z"
    },
    {
      "id": 2,
      "name": "Jane Smith",
      "email": "jane@example.com",
      "created_at": "2024-01-01T12:00:00Z"
    }
  ]
}
```

**Пример:**
```bash
curl http://localhost/api/users
```

### 4. Создание пользователя

Создание нового пользователя.

```http
POST /api/users
Content-Type: application/json
```

**Тело запроса:**
```json
{
  "name": "New User",
  "email": "newuser@example.com"
}
```

**Параметры:**
- `name` (string, required) - Имя пользователя
- `email` (string, required) - Email пользователя (должен быть валидным)

**Ответ (успех):**
```json
{
  "user": {
    "id": 3,
    "name": "New User",
    "email": "newuser@example.com",
    "created_at": "2024-01-01T12:00:00Z"
  }
}
```

**Ответ (ошибка валидации):**
```json
{
  "error": "Invalid request body"
}
```

**Ответ (конфликт):**
```json
{
  "error": "User with this email already exists"
}
```

**Примеры:**

Успешное создание:
```bash
curl -X POST http://localhost/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Test User", "email": "test@example.com"}'
```

Невалидные данные:
```bash
curl -X POST http://localhost/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "", "email": "invalid-email"}'
```

Дублирующийся email:
```bash
curl -X POST http://localhost/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Another User", "email": "john@example.com"}'
```

## Модели данных

### User

```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "created_at": "2024-01-01T12:00:00Z"
}
```

**Поля:**
- `id` (integer) - Уникальный идентификатор
- `name` (string) - Имя пользователя
- `email` (string) - Email пользователя (уникальный)
- `created_at` (datetime) - Дата создания

### CreateUserRequest

```json
{
  "name": "New User",
  "email": "newuser@example.com"
}
```

**Поля:**
- `name` (string, required) - Имя пользователя (не пустое)
- `email` (string, required) - Email пользователя (валидный формат)

## Обработка ошибок

Все ошибки возвращаются в формате JSON:

```json
{
  "error": "Описание ошибки"
}
```

### Типичные ошибки

1. **400 Bad Request** - Неверные данные запроса
2. **409 Conflict** - Email уже существует
3. **500 Internal Server Error** - Внутренняя ошибка сервера

## Rate Limiting

API защищен от злоупотреблений:
- **Общие запросы**: 10 запросов в секунду
- **API endpoints**: 20 запросов в секунду

При превышении лимита возвращается `429 Too Many Requests`.

## Мониторинг

### Метрики

Все запросы к API отслеживаются в Prometheus:
- Количество запросов по endpoint
- Длительность запросов
- Коды ответов
- Ошибки

### Логирование

Все запросы логируются с уровнем INFO:
```json
{
  "level": "info",
  "method": "POST",
  "path": "/api/users",
  "status": 201,
  "latency": "15.2ms",
  "client_ip": "192.168.1.1"
}
```

## Примеры использования

### Полный цикл работы с API

```bash
# 1. Проверка здоровья
curl http://localhost/health

# 2. Получение списка пользователей
curl http://localhost/api/users

# 3. Создание нового пользователя
curl -X POST http://localhost/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice Johnson", "email": "alice@example.com"}'

# 4. Проверка обновленного списка
curl http://localhost/api/users

# 5. Получение метрик
curl http://localhost/metrics
```

### Тестирование с помощью jq

```bash
# Получение количества пользователей
curl -s http://localhost/api/users | jq '.users | length'

# Получение списка email адресов
curl -s http://localhost/api/users | jq '.users[].email'

# Создание пользователя и получение ID
curl -s -X POST http://localhost/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Bob Wilson", "email": "bob@example.com"}' | jq '.user.id'
```

## Версионирование

Текущая версия API: **v1**

В будущих версиях API будет поддерживать версионирование через заголовок `Accept` или в URL.

## Поддержка

При возникновении проблем с API:

1. Проверьте логи приложения: `docker-compose logs webapp`
2. Проверьте метрики: http://localhost/metrics
3. Проверьте health check: http://localhost/health
4. Обратитесь к документации по развертыванию
