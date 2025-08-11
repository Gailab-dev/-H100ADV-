package insertEvent

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"local.dev/h100_module_c/database"
)

type Tbl_Event_Data struct {
	EvId       uint   `gorm:"primaryKey" json:"id"`
	EvDvId    uint   `json:"ev_dv_id"`
	EvCd       uint   `json:"ev_cd"`
	EvCarNum  string `json:"ev_car_num"`
	EvMovPath string `json:"ev_mov_path"`
	EvImgPath string `json:"ev_img_path"`
	EvDate     string `json:"ev_date"`
	EvElId    uint   `json:"ev_el_id"`
	EvRegDate time.Time   `json:"ev_reg_date"`
}

func InsertEventData() http.HandlerFunc{

	fmt.Println("insertEventData in")

	return func(w http.ResponseWriter, r *http.Request){
		
		// Post 요청이 아닌 경우 실행되지 않음
		if r.Method != http.MethodPost {
			http.Error(w,"POST 요청만 허용됩니다.", http.StatusMethodNotAllowed)
			return 
		}
		fmt.Println("post만 허용")

		// 파일 경로 생성
		var eventData Tbl_Event_Data
		// eventData.EvImgPath = generateImgPath.Generate(eventData.EvDvId)
		
		// JSON 파일 디코딩
		err := json.NewDecoder(r.Body).Decode(&eventData)
		if(err != nil){
			http.Error(w,"JSON 파싱 오류",http.StatusBadRequest)
			return 
		}
		fmt.Println("JSON 파싱")

		// DB Insert
		result := database.DBConn.Create(&eventData)
		if(result.Error != nil){
			log.Println("INSERT 실패", result.Error)
			http.Error(w,"DB 삽입 실패", http.StatusInternalServerError)
			return
		}
		fmt.Fprintf(w,"INSERT 성공! ID : %d\n",eventData.EvId)
		

	}
}