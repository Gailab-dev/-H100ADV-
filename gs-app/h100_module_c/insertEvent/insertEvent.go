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
	EvId           uint      `gorm:"primaryKey" json:"id"`
	EvDvId         uint      `json:"ev_dv_id"`
	EvSerialNumber string    `json:"ev_serial_number"`
	EvDvIp         string    `json:"ev_dv_ip"`
	EvDvName       string    `json:"ev_dv_name"`
	EvDvAddr       string    `json:"ev_dv_addr"`
	EvCd           uint      `json:"ev_cd"`
	EvCarNum       string    `json:"ev_car_num"`
	EvMovPath      string    `json:"ev_mov_path"`
	EvImgPath      string    `json:"ev_img_path"`
	EvDate         string    `json:"ev_date"`
	EvElId         uint      `json:"ev_el_id"`
	EvRegDate      time.Time `json:"ev_reg_date"`
	
}

type Tbl_Device struct {
	DvId           uint   `gorm:"primaryKey" json:"dv_id"`
	DvIp           string `json:"dv_ip"`
	DvSerialNumber string `json:"dv_serial_number"`
	DvName         string `json:"dv_name"`
	DvAddr         string `json:"dv_addr"`
}

// TableName 메서드로 실제 테이블명 지정 (GORM의 자동 복수형 변환 방지)
func (Tbl_Device) TableName() string {
	return "tbl_device"
}

func InsertEventData() http.HandlerFunc {

	fmt.Println("insertEventData in")

	return func(w http.ResponseWriter, r *http.Request) {

		// Post 요청이 아닌 경우 실행되지 않음
		if r.Method != http.MethodPost {
			http.Error(w, "POST 요청만 허용됩니다.", http.StatusMethodNotAllowed)
			return
		}
		fmt.Println("post만 허용")

		// JSON 데이터 파싱
		var eventData Tbl_Event_Data

		err := json.NewDecoder(r.Body).Decode(&eventData)
		if err != nil {
			http.Error(w, "JSON 파싱 오류", http.StatusBadRequest)
			log.Println("JSON 파싱 오류:", err)
			return
		}
		fmt.Println("JSON 파싱 완료")

		// ev_serial_number로 tbl_device 조회
		var devices []Tbl_Device
		result := database.DBConn.Where("dv_serial_number = ?", eventData.EvSerialNumber).Find(&devices)
		if result.Error != nil {
			log.Println("디바이스 조회 실패:", result.Error)
			http.Error(w, "디바이스 조회 실패", http.StatusInternalServerError)
			return
		}

		// 조회된 디바이스가 없는 경우
		if len(devices) == 0 {
			log.Printf("일치하는 디바이스 없음 - serial_number: %s\n", eventData.EvSerialNumber)
			http.Error(w, "일치하는 디바이스가 없습니다", http.StatusNotFound)
			return
		}

		fmt.Printf("조회된 디바이스 수: %d\n", len(devices))

		// 조회된 디바이스 개수만큼 tbl_event_data에 insert
		insertedCount := 0
		var insertedIds []uint

		for _, device := range devices {
			// 각 디바이스에 대해 이벤트 데이터 생성
			newEventData := Tbl_Event_Data{
				EvDvId:         device.DvId,
				EvSerialNumber: eventData.EvSerialNumber,
				EvDvIp:         device.DvIp,
				EvDvName:       device.DvName,
				EvDvAddr:       device.DvAddr,
				EvCd:           eventData.EvCd,
				EvCarNum:       eventData.EvCarNum,
				EvMovPath:      eventData.EvMovPath,
				EvImgPath:      eventData.EvImgPath,
				EvDate:         eventData.EvDate,
				EvElId:         eventData.EvElId,
				EvRegDate:      time.Now(),
			}

			// DB Insert
			insertResult := database.DBConn.Create(&newEventData)
			if insertResult.Error != nil {
				log.Printf("INSERT 실패 (디바이스 ID: %d): %v\n", device.DvId, insertResult.Error)
				continue
			}

			insertedCount++
			insertedIds = append(insertedIds, newEventData.EvId)
			fmt.Printf("INSERT 성공 - 디바이스 ID: %d, 이벤트 ID: %d\n", device.DvId, newEventData.EvId)
		}

		// 응답
		if insertedCount == 0 {
			http.Error(w, "모든 INSERT 실패", http.StatusInternalServerError)
			return
		}

		response := map[string]interface{}{
			"success":        true,
			"inserted_count": insertedCount,
			"inserted_ids":   insertedIds,
			"message":        fmt.Sprintf("%d개의 이벤트 데이터 삽입 성공", insertedCount),
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(response)
	}
}