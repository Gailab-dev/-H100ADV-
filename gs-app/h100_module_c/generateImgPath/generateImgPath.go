package generateImgPath

import (
	"strconv"
	"time"
)

var token int = 0; //토큰값
var lastDate time.Time = time.Now(); // 마지막 이벤트 발생일

func Generate(EvDvId uint) string {

	now := time.Now()

	// 마지막 이벤트 발생이 현재 날짜보다 작다면, 현재 날짜로 변경하고 token 초기화
	if lastDate.Before(now)  {
		lastDate = now
		token = 0;
	} 

	// 토큰값을 증가시키고, string 생성
	token++;
	dateDir := lastDate.Format("20201212")
	dateStr := lastDate.Format("20201212_121212")
	
	//return string생성
	resultStr := "/img/" + dateDir +"/" +dateStr + "_" + strconv.FormatUint(uint64(EvDvId),10) + "_" +strconv.Itoa(token) + ".png"
	return resultStr
}
