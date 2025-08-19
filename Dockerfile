# Multi-stage build для оптимизации размера образа
FROM golang:1.25-alpine AS builder

# Установка необходимых пакетов для сборки
RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

# Копирование файлов зависимостей
COPY go.mod go.sum ./

# Загрузка зависимостей
RUN go mod download

# Копирование исходного кода
COPY . .

# Сборка приложения с оптимизациями
RUN CGO_ENABLED=0 GOOS=linux go build \
    -a -installsuffix cgo \
    -ldflags="-w -s" \
    -o webapp .

# Финальный образ
FROM alpine:latest

# Установка необходимых пакетов
RUN apk --no-cache add ca-certificates tzdata

# Создание non-root пользователя
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

WORKDIR /app

# Копирование бинарного файла из builder stage
COPY --from=builder /app/webapp .

# Установка прав доступа
RUN chown -R appuser:appgroup /app

# Переключение на non-root пользователя
USER appuser

# Переменные окружения
ENV PORT=8080
ENV LOG_LEVEL=INFO
ENV DB_HOST=postgres
ENV DB_PORT=5432
ENV DB_USER=postgres
ENV DB_PASSWORD=password
ENV DB_NAME=webapp

# Открытие порта
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Запуск приложения
CMD ["./webapp"]
