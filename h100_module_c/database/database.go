// ===== database 연동 ====== //
package database

import (
	"fmt"
	"log"
	"os"

	"gopkg.in/yaml.v3"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

// database 설정 파일을 읽어오기 위한 data type을 정의하는 구조체
type Config struct {
	Database struct {
		User     string `yaml:"User"`
		Password string `yaml:"Password"`
		Host     string `yaml:"Host"`
		Port     string `yaml:"Port"`
		Name     string `yaml:"Name"`
	} `yaml:"database"`
}

var (
	DBConn *gorm.DB
)

// DB 접속 정보를 불러와서 mariadb와 연결
func Init() {

	fmt.Println("database Init in")

	var config Config
	if os.Getenv("H100_DB_HOST") != "" {
		config.Database.Host = os.Getenv("H100_DB_HOST")
		config.Database.Port = os.Getenv("H100_DB_PORT")
		config.Database.User = os.Getenv("H100_DB_USER")
		config.Database.Password = os.Getenv("H100_DB_PASSWORD")
		config.Database.Name = os.Getenv("H100_DB_NAME")
	} else {
		data, err := os.ReadFile("./config/database.yml")
		if err != nil {
			log.Fatal("Database configuration is unavailable")
		}
		if err := yaml.Unmarshal(data, &config); err != nil {
			log.Fatal("Invalid database configuration")
		}
	}
	if config.Database.Port == "" {
		config.Database.Port = "3306"
	}
	dsn := config.Database.User + ":" + config.Database.Password + "@tcp(" + config.Database.Host + ":" + config.Database.Port + ")/" + config.Database.Name + "?charset=utf8mb4&parseTime=True&loc=Local"
	var err error
	// DB와 connection pool 생성
	DBConn, err = gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("failed to connect database")
	}
	fmt.Println("db connected")
}

// 오류 발생시 DB connect 종료
func Close() {
	sqlDB, err := DBConn.DB()
	if err != nil {
		log.Fatal("sql.DB 추출 실패:", err)
	}
	sqlDB.Close()
}
