# --- Этап 1: Сборка приложения ---
# Используем стабильную версию Dart SDK как основу для сборки
FROM dart:stable AS builder

# Аргументы для доступа к приватным репозиториям GitHub (если они используются)
ARG GITHUB_PAT
ARG GITHUB_USER

WORKDIR /app

# Копируем файлы зависимостей в первую очередь для эффективного кэширования Docker
COPY pubspec.yaml pubspec.lock ./

# Настраиваем Git для доступа к приватным пакетам через токен
RUN if [ -n "$GITHUB_PAT" ] && [ -n "$GITHUB_USER" ]; then \
    echo "Configuring Git to use provided GitHub token..."; \
    git config --global url."https://${GITHUB_USER}:${GITHUB_PAT}@github.com/".insteadOf "https://github.com/"; \
    else \
    echo "No GitHub token provided. Skipping Git configuration..."; \
    fi

# Загружаем зависимости
RUN dart pub get

# Копируем остальной исходный код
COPY . .

# Компилируем приложение в один исполняемый файл
RUN dart compile exe bin/main.dart -o /server


# --- Этап 2: Создание финального production-образа ---
# Используем легковесный и современный образ Debian 12
FROM debian:12-slim

# Устанавливаем только самые необходимые системные библиотеки
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

# Создаем пользователя без root-прав с фиксированным ID для безопасности и совместимости с K8s
RUN groupadd --system --gid 1001 serverpod && \
    useradd --system --uid 1001 --gid 1001 serverpod

# Копируем скомпилированный бинарный файл из этапа сборки
COPY --from=builder /server /usr/local/bin/server

# Копируем статические ассеты и конфигурации
COPY --from=builder /app/config/ /app/config/
COPY --from=builder /app/web/ /app/web/
COPY --from=builder /app/migrations/ /app/migrations/

# Устанавливаем права на директорию для нашего пользователя
WORKDIR /app
RUN chown -R serverpod:serverpod /app

# Переключаемся на пользователя без прав root
USER serverpod

# Healthcheck для проверки работоспособности приложения. Kubernetes будет использовать свои проверки,
# но это хорошая практика для самого образа.
# ВАЖНО: Убедитесь, что ваше приложение отвечает на http://localhost:8080/ (веб-сервер).
# Если веб-сервер на другом порту, измените команду.
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8082/ || exit 1

# Открываем порты, которые слушает приложение
EXPOSE 8080
EXPOSE 8081
EXPOSE 8082

# Точка входа - наш скомпилированный сервер
ENTRYPOINT ["/usr/local/bin/server"]

# Параметры по умолчанию. Миграции (--apply-migrations) убраны намеренно.
CMD ["--mode", "production", "--role", "monolith"]