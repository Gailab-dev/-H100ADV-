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
  		User 	string `yaml:"User"`
  		Password string `yaml:"Password"`
  		Host 	string `yaml:"Host"`
  		Port 	string `yaml:"Port"`
		Name 	string `yaml:"Name"`  
	} `yaml:"database"`
}

var (
	DBConn *gorm.DB
)

// DB 접속 정보를 불러와서 mariadb와 연결
func Init(){

	fmt.Println("dataabse Init in")

	// YAML 파일 읽기
	data, err := os.ReadFile("./config/database.yml")
	if err != nil {
		fmt.Println("YAML 파일 읽기 실패")
		log.Fatalf("error: %v", err)
	}

	fmt.Println("YAML 파일 읽기 성공")
	
	// YAML 파싱
	var config Config
	err = yaml.Unmarshal(data, &config)
	if err != nil {
		fmt.Println("파싱 실패")
		log.Fatalf("error: %v", err)
	}
	fmt.Println("파싱 성공")

	// DB Connect
	// [user]:[password]@tcp([host]:[port])/[dbname]?charset=utf8mb4&parseTime=True&loc=Local
	dsn := config.Database.User +":"+ 
		config.Database.Password +"@tcp(" + 
		config.Database.Host + ":" + 
		config.Database.Port + ")/" + 
		config.Database.Name + "?charset=utf8mb4&parseTime=True&loc=Local"
	fmt.Println(dsn)	
	DBConn, err = gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		fmt.Println("failed to connect database")
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