#!/bin/bash

# Скрипт для настройки GitLab репозитория
set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    printf "${GREEN}[INFO]${NC} %s\n" "$1"
}

log_warn() {
    printf "${YELLOW}[WARN]${NC} %s\n" "$1"
}

log_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
}

# Проверка среды выполнения
check_git() {
    if ! command -v git > /dev/null 2>&1; then
        log_warn "Git не доступен в WebContainer среде"
        log_info "Используем альтернативные методы для настройки проекта"
        return 1
    fi
    return 0
}

# Настройка GitLab репозитория
setup_gitlab() {
    log_info "Настройка GitLab репозитория..."
    
    # В WebContainer среде создаем инструкции вместо прямых git команд
    if ! check_git; then
        log_info "Создание инструкций для ручной настройки GitLab..."
        create_gitlab_instructions
        return 0
    fi
    
    # Добавление GitLab remote
    GITLAB_URL="https://gitlab.com/test-task-mitsina/test-task-web-app.git"
    
    if git remote get-url gitlab > /dev/null 2>&1; then
        log_info "GitLab remote уже настроен"
        git remote set-url gitlab $GITLAB_URL
    else
        git remote add gitlab $GITLAB_URL
        log_info "Добавлен GitLab remote: $GITLAB_URL"
    fi
}

# Создание веток для GitLab
setup_branches() {
    log_info "Настройка веток для GitLab..."
    
    if ! check_git; then
        return 0
    fi
    
    if ! git show-ref --verify --quiet refs/heads/develop > /dev/null 2>&1; then
        git checkout -b develop
        log_info "Создана ветка develop"
    fi
    
    # Возврат на main
    git checkout main
}

# Проверка GitLab CI файла
check_gitlab_ci() {
    log_info "Проверка GitLab CI конфигурации..."
    
    if test -f ".gitlab-ci.yml"; then
        log_info "GitLab CI конфигурация найдена"
        
        if command -v gitlab-ci-multi-runner > /dev/null 2>&1; then
            gitlab-ci-multi-runner verify
            log_info "GitLab CI конфигурация валидна"
        else
            log_warn "gitlab-ci-multi-runner не найден, пропускаем валидацию"
        fi
    else
        log_error ".gitlab-ci.yml не найден"
        exit 1
    fi
}

# Настройка переменных окружения для GitLab
setup_gitlab_env() {
    log_info "Настройка переменных окружения для GitLab..."
    
    if ! test -f ".env.gitlab"; then
        cat > .env.gitlab << EOF
# GitLab CI/CD Variables
# Добавьте эти переменные в Settings > CI/CD > Variables

# Staging Environment
STAGING_SSH_PRIVATE_KEY=your_staging_ssh_private_key
STAGING_HOST=staging.example.com
STAGING_USER=deploy
STAGING_DB_HOST=staging-db.example.com
STAGING_DB_PASSWORD=staging_db_password

# Production Environment
PRODUCTION_SSH_PRIVATE_KEY=your_production_ssh_private_key
PRODUCTION_HOST=production.example.com
PRODUCTION_USER=deploy
PRODUCTION_DB_HOST=production-db.example.com
PRODUCTION_DB_PASSWORD=production_db_password

# Container Registry
CI_REGISTRY=registry.gitlab.com
CI_REGISTRY_IMAGE=registry.gitlab.com/test-task-mitsina/test-task-web-app
EOF
        log_info "Создан .env.gitlab файл с примерами переменных"
    else
        log_info ".env.gitlab файл уже существует"
    fi
}

# Создание инструкций для ручной настройки
create_gitlab_instructions() {
    cat > GITLAB_SETUP_INSTRUCTIONS.md << 'EOF'
# Инструкции по настройке GitLab репозитория

## 1. Клонирование и настройка локального репозитория

```bash
# Клонируйте репозиторий локально
git clone https://github.com/your-username/your-repo.git
cd your-repo

# Добавьте GitLab remote
git remote add gitlab https://gitlab.com/test-task-mitsina/test-task-web-app.git

# Создайте develop ветку
git checkout -b develop
git checkout main
```

## 2. Отправка кода в GitLab

```bash
# Отправьте код в GitLab
git push gitlab main
git push gitlab develop
```

## 3. Настройка CI/CD переменных в GitLab

Перейдите в Settings > CI/CD > Variables и добавьте переменные из файла .env.gitlab

EOF
    log_info "Создан файл GITLAB_SETUP_INSTRUCTIONS.md с инструкциями"
}

# Альтернативный метод для WebContainer
push_to_gitlab() {
    if ! check_git; then
        log_info "В WebContainer среде используйте созданные инструкции"
        return 0
    fi
    
    log_info "Отправка кода в GitLab..."
    git add .
    
    if git diff --staged --quiet; then
        log_info "Нет изменений для коммита"
    else
        git commit -m "feat: add GitLab CI/CD configuration and documentation"
        log_info "Создан коммит с GitLab конфигурацией"
    fi
    
    log_info "Отправка в GitLab репозиторий..."
    git push gitlab main
    
    if git show-ref --verify --quiet refs/heads/develop > /dev/null 2>&1; then
        git push gitlab develop
        log_info "Отправлена ветка develop"
    fi
    
    log_info "Код успешно отправлен в GitLab!"
}

# Инструкции по настройке GitLab
show_gitlab_instructions() {
    log_info "=== Инструкции по настройке GitLab ==="
    echo
    log_info "1. Настройте CI/CD Variables в GitLab:"
    echo "   - Перейдите в Settings > CI/CD > Variables"
    echo "   - Добавьте переменные из файла .env.gitlab"
    echo "   - Отметьте чувствительные переменные как 'Masked' и 'Protected'"
    echo
    log_info "2. Включите GitLab Container Registry:"
    echo "   - Перейдите в Packages & Registries > Container Registry"
    echo "   - Registry автоматически доступен для проекта"
    echo
    log_info "3. Настройте Environments:"
    echo "   - Перейдите в Deployments > Environments"
    echo "   - Создайте environments 'staging' и 'production'"
    echo "   - Настройте protection rules для production"
    echo
    log_info "4. Включите Security Features:"
    echo "   - Перейдите в Security & Compliance"
    echo "   - Включите SAST, Dependency Scanning, Container Scanning"
    echo
    log_info "5. Настройте Protected Branches:"
    echo "   - Перейдите в Settings > Repository > Protected branches"
    echo "   - Защитите ветку 'main' от прямых push"
    echo
    log_info "6. Настройте Merge Request approvals:"
    echo "   - Перейдите в Settings > Merge requests"
    echo "   - Настройте обязательные approvals для main ветки"
    echo
    log_info "7. Запустите первый pipeline:"
    echo "   - Pipeline должен запуститься автоматически после push"
    echo "   - Проверьте CI/CD > Pipelines"
    echo
    log_info "GitLab проект: https://gitlab.com/test-task-mitsina/test-task-web-app"
    log_info "Container Registry: registry.gitlab.com/test-task-mitsina/test-task-web-app"
}

# Основная функция
main() {
    log_info "Начало настройки GitLab репозитория..."
    
    if ! check_git; then
        log_warn "Работаем в WebContainer среде без Git"
        log_info "Создаем конфигурационные файлы и инструкции..."
    fi
    
    setup_gitlab
    setup_branches
    check_gitlab_ci
    setup_gitlab_env
    push_to_gitlab
    show_gitlab_instructions
    
    log_info "Настройка GitLab завершена!"
}

# Обработка аргументов
case "${1-setup}" in
    "setup")
        main
        ;;
    "push")
        push_to_gitlab
        ;;
    "env")
        setup_gitlab_env
        ;;
    "check")
        check_gitlab_ci
        ;;
    *)
        echo "Использование: $0 {setup|push|env|check}"
        exit 1
        ;;
esac