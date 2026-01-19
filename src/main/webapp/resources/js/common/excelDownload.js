/**
 * 엑셀 다운로드
 */

// /resources/js/common/excelDownloader.js
(function (global) {
	
  //fetch를 사용하여 폼 값을 back-end에 전송		
  async function postJson(url, body) {
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      credentials: "same-origin",
      cache: "no-store",
      body: JSON.stringify(body),
    });
    return res;
  }

  // 폼에서 값 읽기 (name이 없으면 id로도 시도)
  function getFieldValue(form, keyOrSelector) {
    if (!keyOrSelector) return "";
    // 1) name 기반
    if (form && form.elements && form.elements[keyOrSelector]) {
      return (form.elements[keyOrSelector].value ?? "").trim();
    }
    // 2) selector 기반 (#id, .class, [name=..])
    const el = document.querySelector(keyOrSelector);
    if (el) return (el.value ?? "").trim();

    return "";
  }

  // 매핑에 따라 body 만들기
  function buildBody(form, mapping) {
    // mapping 예시:
    // { startDate: "startDate", endDate: "endDate", searchKeyword: "searchKeyword" }
    const body = {};
    Object.entries(mapping).forEach(([bodyKey, formKeyOrSelector]) => {
      body[bodyKey] = getFieldValue(form, formKeyOrSelector);
    });
    return body;
  }

  /**
   * Excel 다운로드 요청
   * @param {Object} opts
   * @param {string} opts.endpoint - ex) "/deviceList/excelDownload"
   * @param {string} opts.formSelector - ex) "#deviceListSearchForm"
   * @param {Object} opts.mapping - bodyKey -> (form input name) or selector ex) searchKeyword, #input_id
   * @param {"json"|"blob"} [opts.responseType="blob"] - 서버 응답 형태
   * @param {string} [opts.downloadFilename="download.xlsx"] - blob 다운로드 시 파일명
   */
  async function excelDownload(opts) {
    const {
      endpoint,
      formSelector,
      mapping,
      responseType = "blob",
      downloadFilename = "download.xlsx",
    } = opts || {};
	
	// context path
	const CONTEXT_PATH = "/gov-disabled-web-adv";
	
    if (!endpoint) throw new Error("endpoint is required");
    if (!formSelector) throw new Error("formSelector is required");
    if (!mapping) throw new Error("mapping is required");

    const form = document.querySelector(formSelector);
    if (!form) throw new Error("Form not found: " + formSelector);

    const body = buildBody(form, mapping);

    const url = CONTEXT_PATH + endpoint;
    const res = await postJson(url, body);

    if (!res.ok) {
      // 필요하면 서버 에러 메시지 읽기
      // const text = await res.text().catch(() => "");
      throw new Error("Request failed: " + res.status);
    }

    // 서버가 json으로만 응답하는 경우
    if (responseType === "json") {
      return await res.json();
    }

    // 서버가 실제 엑셀 파일(blob) 내려주는 경우
    const blob = await res.blob();

    // 다운로드 트리거
    const a = document.createElement("a");  // 가상 a 태그 생성
    const blobUrl = window.URL.createObjectURL(blob); // 서버가 내려준 엑셀 파일의 url
    a.href = blobUrl;
    a.download = downloadFilename;
    document.body.appendChild(a);
    a.click(); // 가상으로 생성한 a 태그를 가상으로 클릭하여 해당 url 실행, 엑셀 다운로드
    a.remove(); // 가상 a 태그 제거
    window.URL.revokeObjectURL(blobUrl);

    return true;
  }

  global.ExcelDownloader = { excelDownload };
})(window);
