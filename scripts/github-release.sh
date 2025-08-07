#!/bin/bash

# Скрипт для создания GitHub releases
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

# Проверка наличия gh CLI
check_gh() {
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) не установлен"
        log_info "Установите: https://cli.github.com/"
        exit 1
    fi
}

# Получение версии из git tags
get_version() {
    local version=$1
    if [ -z "$version" ]; then
        log_error "Укажите версию (например: v1.0.0)"
        exit 1
    fi
    
    # Проверка формата версии
    if [[ ! $version =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_error "Неверный формат версии. Используйте формат vX.Y.Z"
        exit 1
    fi
    
    echo $version
}

# Создание тега
create_tag() {
    local version=$1
    local message=${2:-"Release $version"}
    
    log_info "Создание тега $version..."
    git tag -a $version -m "$message"
    git push origin $version
}

# Создание release
create_release() {
    local version=$1
    local title=${2:-"Release $version"}
    local notes=${3:-""}
    
    log_info "Создание GitHub release $version..."
    
    # Создание release notes если не указаны
    if [ -z "$notes" ]; then
        notes=$(git log --oneline $(git describe --tags --abbrev=0)..HEAD | head -20)
    fi
    
    # Создание release через GitHub CLI
    gh release create $version \
        --title "$title" \
        --notes "$notes" \
        --draft=false \
        --prerelease=false
}

# Сборка и публикация Docker образа
build_and_publish() {
    local version=$1
    
    log_info "Сборка Docker образа для версии $version..."
    
    # Получение информации о репозитории
    local repo=$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^/]*\/[^/]*\)\.git/\1/')
    local image_name="ghcr.io/$repo:$version"
    
    # Сборка образа
    docker build -t $image_name .
    
    # Публикация образа
    log_info "Публикация образа $image_name..."
    docker push $image_name
    
    # Публикация latest тега
    local latest_image="ghcr.io/$repo:latest"
    docker tag $image_name $latest_image
    docker push $latest_image
    
    log_info "Docker образы опубликованы:"
    log_info "  - $image_name"
    log_info "  - $latest_image"
}

# Основная функция
main() {
    local version=$(get_version $1)
    local title=${2:-"Release $version"}
    local notes=${3:-""}
    
    log_info "Начало создания release $version..."
    
    check_git
    check_gh
    
    # Проверка, что мы в main ветке
    local current_branch=$(git branch --show-current)
    if [ "$current_branch" != "main" ]; then
        log_error "Вы должны быть в main ветке для создания release"
        log_info "Текущая ветка: $current_branch"
        exit 1
    fi
    
    # Проверка, что нет несохраненных изменений
    if [ -n "$(git status --porcelain)" ]; then
        log_error "Есть несохраненные изменения. Сделайте commit или stash"
        git status --short
        exit 1
    fi
    
    # Создание тега
    create_tag $version "$title"
    
    # Создание GitHub release
    create_release $version "$title" "$notes"
    
    # Сборка и публикация Docker образа
    build_and_publish $version
    
    log_info "Release $version успешно создан!"
    log_info "Проверьте: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^/]*\/[^/]*\)\.git/\1/')/releases"
}

# Обработка аргументов
if [ $# -eq 0 ]; then
    echo "Использование: $0 <version> [title] [notes]"
    echo "Пример: $0 v1.0.0 'Major Release' 'Important bug fixes'"
    exit 1
fi

main "$@"
