package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	_ "github.com/lib/pq"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/sirupsen/logrus"
)

var (
	logger *logrus.Logger
	db     *sql.DB

	// Prometheus метрики
	httpRequestsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"method", "endpoint", "status"},
	)

	httpRequestDuration = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_request_duration_seconds",
			Help:    "HTTP request duration in seconds",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"method", "endpoint"},
	)
)

// User представляет модель пользователя
type User struct {
	ID        int       `json:"id"`
	Name      string    `json:"name"`
	Email     string    `json:"email"`
	CreatedAt time.Time `json:"created_at"`
}

// CreateUserRequest представляет запрос на создание пользователя
type CreateUserRequest struct {
	Name  string `json:"name" binding:"required"`
	Email string `json:"email" binding:"required,email"`
}

func init() {
	// Инициализация логгера
	logger = logrus.New()
	logger.SetFormatter(&logrus.JSONFormatter{})
	logger.SetLevel(logrus.InfoLevel)

	// Настройка уровня логирования из переменной окружения
	if level := os.Getenv("LOG_LEVEL"); level != "" {
		switch level {
		case "DEBUG":
			logger.SetLevel(logrus.DebugLevel)
		case "ERROR":
			logger.SetLevel(logrus.ErrorLevel)
		}
	}

	// Регистрация Prometheus метрик
	prometheus.MustRegister(httpRequestsTotal)
	prometheus.MustRegister(httpRequestDuration)
}

func initDB() error {
	// Параметры подключения к PostgreSQL
	host := getEnv("DB_HOST", "localhost")
	port := getEnv("DB_PORT", "5432")
	user := getEnv("DB_USER", "postgres")
	password := getEnv("DB_PASSWORD", "password")
	dbname := getEnv("DB_NAME", "webapp")

	// Строка подключения
	psqlInfo := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		host, port, user, password, dbname)

	var err error
	db, err = sql.Open("postgres", psqlInfo)
	if err != nil {
		return fmt.Errorf("error opening database: %v", err)
	}

	// Проверка подключения
	if err = db.Ping(); err != nil {
		return fmt.Errorf("error connecting to database: %v", err)
	}

	// Создание таблицы пользователей
	createTableSQL := `
	CREATE TABLE IF NOT EXISTS users (
		id SERIAL PRIMARY KEY,
		name VARCHAR(100) NOT NULL,
		email VARCHAR(100) UNIQUE NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);`

	_, err = db.Exec(createTableSQL)
	if err != nil {
		return fmt.Errorf("error creating table: %v", err)
	}

	// Добавление тестовых данных, если таблица пуста
	var count int
	err = db.QueryRow("SELECT COUNT(*) FROM users").Scan(&count)
	if err != nil {
		return fmt.Errorf("error checking users count: %v", err)
	}

	if count == 0 {
		insertSQL := `
		INSERT INTO users (name, email) VALUES 
		('John Doe', 'john@example.com'),
		('Jane Smith', 'jane@example.com'),
		('Bob Johnson', 'bob@example.com')
		ON CONFLICT (email) DO NOTHING;`

		_, err = db.Exec(insertSQL)
		if err != nil {
			return fmt.Errorf("error inserting test data: %v", err)
		}
		logger.Info("Test users inserted successfully")
	}

	logger.Info("Database initialized successfully")
	return nil
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func setupRouter() *gin.Engine {
	// Настройка Gin
	gin.SetMode(gin.ReleaseMode)
	r := gin.New()

	// Middleware для логирования и метрик
	r.Use(func(c *gin.Context) {
		start := time.Now()

		// Обработка запроса
		c.Next()

		// Логирование
		logger.WithFields(logrus.Fields{
			"status":     c.Writer.Status(),
			"latency":    time.Since(start),
			"client_ip":  c.ClientIP(),
			"method":     c.Request.Method,
			"path":       c.Request.URL.Path,
			"user_agent": c.Request.UserAgent(),
		}).Info("HTTP Request")

		// Обновление метрик
		httpRequestsTotal.WithLabelValues(
			c.Request.Method,
			c.Request.URL.Path,
			fmt.Sprintf("%d", c.Writer.Status()),
		).Inc()

		httpRequestDuration.WithLabelValues(
			c.Request.Method,
			c.Request.URL.Path,
		).Observe(time.Since(start).Seconds())
	})

	// Middleware для восстановления после паники
	r.Use(gin.Recovery())

	// Health check endpoint
	r.GET("/health", func(c *gin.Context) {
		logger.Debug("Health check requested")
		c.JSON(http.StatusOK, gin.H{
			"status":    "healthy",
			"timestamp": time.Now().UTC(),
			"service":   "web-app",
		})
	})

	// Metrics endpoint для Prometheus
	r.GET("/metrics", gin.WrapH(promhttp.Handler()))

	// API routes
	api := r.Group("/api")
	{
		// Получить список пользователей
		api.GET("/users", getUsers)

		// Создать пользователя
		api.POST("/users", createUser)
	}

	return r
}

func getUsers(c *gin.Context) {
	logger.Debug("Getting users list")

	rows, err := db.Query("SELECT id, name, email, created_at FROM users ORDER BY id")
	if err != nil {
		logger.WithError(err).Error("Error querying users")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch users"})
		return
	}
	defer rows.Close()

	var users []User
	for rows.Next() {
		var user User
		err := rows.Scan(&user.ID, &user.Name, &user.Email, &user.CreatedAt)
		if err != nil {
			logger.WithError(err).Error("Error scanning user row")
			continue
		}
		users = append(users, user)
	}

	if err = rows.Err(); err != nil {
		logger.WithError(err).Error("Error iterating over users")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch users"})
		return
	}

	logger.WithField("count", len(users)).Info("Users retrieved successfully")
	c.JSON(http.StatusOK, gin.H{"users": users})
}

func createUser(c *gin.Context) {
	var req CreateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		logger.WithError(err).Error("Invalid request body")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	logger.WithFields(logrus.Fields{
		"name":  req.Name,
		"email": req.Email,
	}).Debug("Creating new user")

	// Проверка на существующий email
	var existingID int
	err := db.QueryRow("SELECT id FROM users WHERE email = $1", req.Email).Scan(&existingID)
	if err == nil {
		logger.WithField("email", req.Email).Warn("User with this email already exists")
		c.JSON(http.StatusConflict, gin.H{"error": "User with this email already exists"})
		return
	}

	// Создание нового пользователя
	var user User
	err = db.QueryRow(
		"INSERT INTO users (name, email) VALUES ($1, $2) RETURNING id, name, email, created_at",
		req.Name, req.Email,
	).Scan(&user.ID, &user.Name, &user.Email, &user.CreatedAt)

	if err != nil {
		logger.WithError(err).Error("Error creating user")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
		return
	}

	logger.WithField("user_id", user.ID).Info("User created successfully")
	c.JSON(http.StatusCreated, gin.H{"user": user})
}

func main() {
	logger.Info("Starting web application...")

	// Инициализация базы данных
	if err := initDB(); err != nil {
		logger.WithError(err).Fatal("Failed to initialize database")
	}
	defer db.Close()

	// Настройка роутера
	r := setupRouter()

	// Получение порта из переменной окружения
	port := getEnv("PORT", "8080")

	logger.WithField("port", port).Info("Server starting on port " + port)

	// Запуск сервера
	if err := r.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}
