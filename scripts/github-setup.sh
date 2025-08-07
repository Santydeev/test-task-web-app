#!/bin/bash

# Скрипт для настройки GitHub репозитория
set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка наличия git
check_git() {
    if ! command -v git &> /dev/null; then
        log_error "Git не установлен"
        exit 1
    fi
}

# Настройка GitHub репозитория
setup_github() {
    log_info "Настройка GitHub репозитория..."
    
    # Проверка, что мы в git репозитории
    if [ ! -d ".git" ]; then
        log_error "Не найден .git каталог. Запустите скрипт из корня репозитория."
        exit 1
    fi
    
    # Получение информации о репозитории
    REPO_URL=$(git config --get remote.origin.url)
    if [[ $REPO_URL == *"github.com"* ]]; then
        log_info "GitHub репозиторий обнаружен: $REPO_URL"
    else
        log_warn "Репозиторий не является GitHub репозиторием: $REPO_URL"
        log_info "Убедитесь, что вы работаете с GitHub репозиторием"
    fi
}

# Создание веток
setup_branches() {
    log_info "Настройка веток..."
    
    # Создание develop ветки
    if ! git show-ref --verify --quiet refs/heads/develop; then
        git checkout -b develop
        log_info "Создана ветка develop"
    else
        log_info "Ветка develop уже существует"
    fi
    
    # Возврат на main
    git checkout main
}

# Настройка GitHub Actions
setup_actions() {
    log_info "Проверка GitHub Actions..."
    
    if [ -d ".github/workflows" ]; then
        log_info "GitHub Actions workflows найдены:"
        ls -la .github/workflows/
    else
        log_error "GitHub Actions workflows не найдены"
        exit 1
    fi
}

# Проверка зависимостей
check_dependencies() {
    log_info "Проверка зависимостей..."
    
    # Проверка Go модулей
    if [ -f "go.mod" ]; then
        log_info "Go модули найдены"
        go mod tidy
    else
        log_error "go.mod не найден"
        exit 1
    fi
    
    # Проверка Docker
    if command -v docker &> /dev/null; then
        log_info "Docker найден: $(docker --version)"
    else
        log_warn "Docker не найден"
    fi
    
    # Проверка Docker Compose
    if command -v docker-compose &> /dev/null; then
        log_info "Docker Compose найден: $(docker-compose --version)"
    else
        log_warn "Docker Compose не найден"
    fi
}

# Создание .env файла
setup_env() {
    log_info "Настройка переменных окружения..."
    
    if [ ! -f ".env" ]; then
        if [ -f "env.example" ]; then
            cp env.example .env
            log_info "Создан .env файл из env.example"
            log_warn "Отредактируйте .env файл с вашими настройками"
        else
            log_error "env.example не найден"
            exit 1
        fi
    else
        log_info ".env файл уже существует"
    fi
}

# Проверка структуры проекта
check_structure() {
    log_info "Проверка структуры проекта..."
    
    required_files=(
        "main.go"
        "go.mod"
        "Dockerfile"
        "docker-compose.yml"
        "README.md"
        ".github/workflows/ci-cd.yml"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            log_info "✓ $file"
        else
            log_error "✗ $file не найден"
        fi
    done
}

# Инструкции по настройке
show_instructions() {
    log_info "=== Инструкции по настройке GitHub ==="
    echo
    log_info "1. Настройте GitHub Secrets в репозитории:"
    echo "   - Перейдите в Settings > Secrets and variables > Actions"
    echo "   - Добавьте следующие secrets:"
    echo "     * STAGING_SSH_PRIVATE_KEY"
    echo "     * PRODUCTION_SSH_PRIVATE_KEY"
    echo
    log_info "2. Включите GitHub Container Registry:"
    echo "   - Перейдите в Settings > Packages"
    echo "   - Убедитесь, что Container registry включен"
    echo
    log_info "3. Настройте Environments:"
    echo "   - Создайте environments 'staging' и 'production'"
    echo "   - Добавьте protection rules если необходимо"
    echo
    log_info "4. Включите Dependabot:"
    echo "   - Перейдите в Security > Dependabot"
    echo "   - Включите alerts для Go, Docker, GitHub Actions"
    echo
    log_info "5. Настройте CodeQL:"
    echo "   - Перейдите в Security > Code scanning"
    echo "   - Включите CodeQL analysis"
    echo
    log_info "6. Запустите первый workflow:"
    echo "   - Сделайте push в main ветку"
    echo "   - Проверьте Actions tab"
    echo
}

# Основная функция
main() {
    log_info "Начало настройки GitHub репозитория..."
    
    check_git
    setup_github
    setup_branches
    setup_actions
    check_dependencies
    setup_env
    check_structure
    show_instructions
    
    log_info "Настройка завершена!"
}

# Обработка аргументов
case "${1:-setup}" in
    "setup")
        main
        ;;
    "check")
        check_structure
        check_dependencies
        ;;
    "env")
        setup_env
        ;;
    "branches")
        setup_branches
        ;;
    *)
        echo "Использование: $0 {setup|check|env|branches}"
        exit 1
        ;;
esac
