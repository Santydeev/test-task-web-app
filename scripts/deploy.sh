#!/bin/bash

# Скрипт для развертывания приложения
set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функции для логирования
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка наличия Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker не установлен"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose не установлен"
        exit 1
    fi
}

# Проверка файла .env
check_env() {
    if [ ! -f .env ]; then
        log_warn "Файл .env не найден, создаю из примера..."
        cp env.example .env
        log_info "Файл .env создан. Отредактируйте его при необходимости."
    fi
}

# Остановка и удаление старых контейнеров
cleanup() {
    log_info "Остановка старых контейнеров..."
    docker-compose down --remove-orphans
}

# Сборка и запуск
deploy() {
    log_info "Сборка и запуск приложения..."
    docker-compose up -d --build
    
    log_info "Ожидание запуска сервисов..."
    sleep 30
    
    # Проверка health check
    log_info "Проверка health check..."
    if curl -f http://localhost/health > /dev/null 2>&1; then
        log_info "Приложение успешно запущено!"
    else
        log_error "Health check не прошел"
        exit 1
    fi
}

# Проверка статуса
status() {
    log_info "Статус сервисов:"
    docker-compose ps
    
    log_info "Логи приложения:"
    docker-compose logs --tail=20 webapp
}

# Основная функция
main() {
    log_info "Начало развертывания..."
    
    check_docker
    check_env
    cleanup
    deploy
    status
    
    log_info "Развертывание завершено!"
    log_info "Доступные сервисы:"
    log_info "  - Веб-приложение: http://localhost"
    log_info "  - GitLab: http://localhost:8081"
    log_info "  - Grafana: http://localhost:3000"
    log_info "  - Prometheus: http://localhost:9090"
}

# Обработка аргументов командной строки
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "stop")
        log_info "Остановка сервисов..."
        docker-compose down
        ;;
    "restart")
        log_info "Перезапуск сервисов..."
        docker-compose restart
        ;;
    "logs")
        docker-compose logs -f
        ;;
    "status")
        status
        ;;
    "clean")
        log_info "Полная очистка..."
        docker-compose down -v --remove-orphans
        docker system prune -f
        ;;
    *)
        echo "Использование: $0 {deploy|stop|restart|logs|status|clean}"
        exit 1
        ;;
esac
