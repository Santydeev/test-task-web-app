# GitHub Setup Guide

Подробное руководство по настройке GitHub репозитория для этого проекта.

## 🚀 Быстрая настройка

### 1. Клонирование репозитория
```bash
git clone https://github.com/Santydeev/test-task-web-app.git
cd test-task-web-app
```

### 2. Настройка GitHub репозитория
```bash
./scripts/github-setup.sh
```

### 3. Запуск приложения
```bash
./scripts/deploy.sh
```

## 📋 Требования

### Системные требования
- **Git** 2.30+
- **Docker** 20.10+
- **Docker Compose** 2.0+
- **GitHub CLI** (опционально, для releases)

### GitHub требования
- GitHub аккаунт
- Репозиторий с включенными Actions
- Доступ к GitHub Container Registry

## ⚙️ Настройка GitHub репозитория

### 1. Включение GitHub Actions

1. Перейдите в Settings > Actions > General
2. Убедитесь, что Actions включены
3. Настройте permissions:
   - **Actions permissions**: Allow all actions and reusable workflows
   - **Workflow permissions**: Read and write permissions

### 2. Настройка GitHub Container Registry

1. Перейдите в Settings > Packages
2. Убедитесь, что Container registry включен
3. Настройте visibility (public/private)

### 3. Настройка Environments

#### Staging Environment
1. Перейдите в Settings > Environments
2. Создайте environment `staging`
3. Добавьте protection rules если необходимо

#### Production Environment
1. Создайте environment `production`
2. Добавьте protection rules:
   - **Required reviewers**: Добавьте ревьюеров
   - **Wait timer**: 5 минут (опционально)
   - **Deployment branches**: main

### 4. Настройка Secrets

Перейдите в Settings > Secrets and variables > Actions и добавьте:

#### Обязательные Secrets
- `STAGING_SSH_PRIVATE_KEY` - SSH ключ для staging сервера
- `PRODUCTION_SSH_PRIVATE_KEY` - SSH ключ для production сервера

#### Опциональные Secrets
- `DOCKER_USERNAME` - Docker Hub username (если используете)
- `DOCKER_PASSWORD` - Docker Hub password (если используете)

### 5. Настройка Dependabot

1. Перейдите в Security > Dependabot
2. Включите alerts для:
   - **Go** (gomod)
   - **Docker** (docker)
   - **GitHub Actions** (github-actions)

### 6. Настройка CodeQL

1. Перейдите в Security > Code scanning
2. Включите CodeQL analysis
3. Настройте автоматический анализ

## 🔄 Workflow Lifecycle

### 1. Push в main ветку
```bash
git add .
git commit -m "feat: add new feature"
git push origin main
```

**Что происходит:**
- ✅ Валидация кода (go vet, go fmt)
- ✅ Запуск тестов с покрытием
- ✅ Сборка Docker образа
- ✅ Сканирование безопасности
- ✅ Автоматическое развертывание в staging

### 2. Создание Pull Request
```bash
git checkout -b feature/new-feature
# ... внесите изменения ...
git push origin feature/new-feature
# Создайте PR через GitHub UI
```

**Что происходит:**
- ✅ Валидация кода
- ✅ Запуск тестов
- ✅ Сканирование безопасности
- ✅ CodeQL анализ
- ✅ Dependency review

### 3. Создание Release
```bash
./scripts/github-release.sh v1.0.0 "Major Release" "Important bug fixes"
```

**Что происходит:**
- ✅ Создание git tag
- ✅ Создание GitHub release
- ✅ Публикация Docker образа в ghcr.io
- ✅ Автоматическое развертывание в production

## 📊 Мониторинг и метрики

### GitHub Actions метрики
- **Время выполнения**: Отслеживается в Actions tab
- **Успешность**: Процент успешных runs
- **Покрытие тестами**: Отображается в PR

### Docker образы
- **Размер образа**: Оптимизирован multi-stage build
- **Уязвимости**: Сканируются Trivy
- **Слои**: Кэшируются для ускорения сборки

## 🔐 Безопасность

### Автоматические проверки
- **CodeQL**: Статический анализ кода
- **Dependabot**: Обновление зависимостей
- **Trivy**: Сканирование уязвимостей
- **Dependency review**: Проверка зависимостей

### Ручные проверки
- **Code review**: Обязательно для production
- **Security review**: Для критических изменений
- **Performance testing**: Для major releases

## 🚨 Troubleshooting

### Проблемы с Actions

#### Workflow не запускается
1. Проверьте, что Actions включены
2. Убедитесь, что файл `.github/workflows/ci-cd.yml` существует
3. Проверьте синтаксис YAML

#### Ошибки сборки
1. Проверьте логи в Actions tab
2. Убедитесь, что все зависимости указаны в `go.mod`
3. Проверьте Dockerfile на ошибки

#### Проблемы с Container Registry
1. Убедитесь, что registry включен
2. Проверьте permissions в Settings > Actions
3. Убедитесь, что `GITHUB_TOKEN` доступен

### Проблемы с развертыванием

#### Staging deployment fails
1. Проверьте `STAGING_SSH_PRIVATE_KEY` secret
2. Убедитесь, что staging сервер доступен
3. Проверьте SSH соединение

#### Production deployment fails
1. Проверьте `PRODUCTION_SSH_PRIVATE_KEY` secret
2. Убедитесь, что environment protection rules настроены
3. Проверьте, что release создан правильно

## 📈 Оптимизация

### Ускорение сборки
- **Кэширование**: Docker layers кэшируются
- **Parallel jobs**: Тесты и сборка выполняются параллельно
- **Matrix builds**: Для разных версий Go (если нужно)

### Уменьшение размера образа
- **Multi-stage build**: Используется в Dockerfile
- **Alpine Linux**: Минимальный базовый образ
- **Non-root user**: Безопасность и размер

## 🔄 Обновление

### Обновление зависимостей
```bash
# Автоматически через Dependabot
# Или вручную:
go get -u ./...
go mod tidy
```

### Обновление GitHub Actions
```bash
# Проверьте новые версии actions в workflows
# Обновите версии в .github/workflows/*.yml
```

### Обновление Docker образов
```bash
# Обновите базовые образы в Dockerfile
# Пересоберите образы
docker-compose build --no-cache
```

## 📞 Поддержка

### Полезные ссылки
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Dependabot](https://docs.github.com/en/code-security/dependabot)
- [CodeQL](https://docs.github.com/en/code-security/code-scanning)

### Получение помощи
1. Проверьте [Issues](../../issues) на GitHub
2. Создайте новый issue с подробным описанием
3. Используйте [Discussions](../../discussions) для вопросов

---

**Автор**: DevOps Team  
**Версия**: 1.0.0  
**Дата**: 2024
