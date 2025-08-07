package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

func setupTestRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	r := setupRouter()
	return r
}

func TestHealthEndpoint(t *testing.T) {
	r := setupTestRouter()
	
	req, _ := http.NewRequest("GET", "/health", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	
	assert.Equal(t, http.StatusOK, w.Code)
	
	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	
	assert.Equal(t, "healthy", response["status"])
	assert.Equal(t, "web-app", response["service"])
}

func TestMetricsEndpoint(t *testing.T) {
	r := setupTestRouter()
	
	req, _ := http.NewRequest("GET", "/metrics", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	
	assert.Equal(t, http.StatusOK, w.Code)
	assert.Contains(t, w.Body.String(), "http_requests_total")
}

func TestGetUsersEndpoint(t *testing.T) {
	r := setupTestRouter()
	
	req, _ := http.NewRequest("GET", "/api/users", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	
	assert.Equal(t, http.StatusOK, w.Code)
	
	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	
	users, exists := response["users"]
	assert.True(t, exists)
	assert.NotNil(t, users)
}

func TestCreateUserEndpoint(t *testing.T) {
	r := setupTestRouter()
	
	userData := map[string]interface{}{
		"name":  "Test User",
		"email": "test@example.com",
	}
	
	jsonData, _ := json.Marshal(userData)
	req, _ := http.NewRequest("POST", "/api/users", bytes.NewBuffer(jsonData))
	req.Header.Set("Content-Type", "application/json")
	
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	
	assert.Equal(t, http.StatusCreated, w.Code)
	
	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	
	user, exists := response["user"]
	assert.True(t, exists)
	assert.NotNil(t, user)
}

func TestCreateUserInvalidData(t *testing.T) {
	r := setupTestRouter()
	
	// Тест с невалидными данными
	userData := map[string]interface{}{
		"name": "", // Пустое имя
		"email": "invalid-email", // Невалидный email
	}
	
	jsonData, _ := json.Marshal(userData)
	req, _ := http.NewRequest("POST", "/api/users", bytes.NewBuffer(jsonData))
	req.Header.Set("Content-Type", "application/json")
	
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	
	assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestGetEnvFunction(t *testing.T) {
	// Тест функции getEnv
	result := getEnv("NON_EXISTENT_VAR", "default_value")
	assert.Equal(t, "default_value", result)
}

func BenchmarkHealthEndpoint(b *testing.B) {
	r := setupTestRouter()
	
	for i := 0; i < b.N; i++ {
		req, _ := http.NewRequest("GET", "/health", nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
	}
}

func BenchmarkGetUsersEndpoint(b *testing.B) {
	r := setupTestRouter()
	
	for i := 0; i < b.N; i++ {
		req, _ := http.NewRequest("GET", "/api/users", nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
	}
}
