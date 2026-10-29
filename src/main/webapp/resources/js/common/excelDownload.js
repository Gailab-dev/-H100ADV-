// /resources/js/common/excelDownloader.js
(function (global) {

  // 컨텍스트 경로(ROOT 배포면 빈 문자열, 예: "" 또는 "/앱이름").
  // 우선순위: ① 호출부가 opts.contextPath 로 넘긴 값 ② 공통 헤더(template.jsp)가 서버에서 심어 준 window.APP_CTX
  // ③ 이 스크립트 자신의 URL(…/resources/js/common/excelDownload.js)에서 역산. 어떤 배포 경로도 코드에 고정하지 않는다.
  const SCRIPT_CTX = (function () {
    try {
      const src = document.currentScript && document.currentScript.src;
      if (!src) return "";
      const path = new URL(src, window.location.href).pathname;
      const idx = path.indexOf("/resources/js/common/");
      return idx >= 0 ? path.slice(0, idx) : "";
    } catch (e) {
      return "";
    }
  })();

  function resolveContextPath(explicit) {
    if (typeof explicit === "string") return explicit;
    if (typeof global.APP_CTX === "string") return global.APP_CTX;
    return SCRIPT_CTX;
  }

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

  function getFieldValue(form, keyOrSelector) {
    if (!keyOrSelector) return "";
    if (form && form.elements && form.elements[keyOrSelector]) {
      return (form.elements[keyOrSelector].value ?? "").trim();
    }
    const el = document.querySelector(keyOrSelector);
    if (el) return (el.value ?? "").trim();
    return "";
  }

  function buildBody(form, mapping) {
    const body = {};
    Object.entries(mapping).forEach(([bodyKey, formKeyOrSelector]) => {
      body[bodyKey] = getFieldValue(form, formKeyOrSelector);
    });
    return body;
  }

  function downloadBlob(blob, downloadFilename) {
    const a = document.createElement("a");
    const blobUrl = window.URL.createObjectURL(blob);
    a.href = blobUrl;
    a.download = downloadFilename || "download.xlsx";
    document.body.appendChild(a);
    a.click();
    a.remove();
    window.URL.revokeObjectURL(blobUrl);
  }

  /**
   * Excel 다운로드 요청 (폼 기반 + params 기반 둘 다 지원)
   * opts:
   * - endpoint: 필수
   * - params: (선택) body로 직접 보낼 값
   * - formSelector/mapping: (선택) 폼에서 읽어 body 구성
   */
  async function excelDownload(opts) {
    const {
      endpoint,
      params,                 // ✅ 추가
      formSelector,
      mapping,
      responseType = "blob",
      downloadFilename = "download.xlsx",
      contextPath,            // (선택) 지정하지 않으면 resolveContextPath() 가 결정
    } = opts || {};

    if (!endpoint) throw new Error("endpoint is required");

    // 1) body 만들기
    let body = {};

    // (a) 폼 기반
    if (formSelector && mapping) {
      const form = document.querySelector(formSelector);
      if (!form) throw new Error("Form not found: " + formSelector);
      body = buildBody(form, mapping);
    }

    // (b) params 직접
    if (params && typeof params === "object") {
      body = { ...body, ...params }; // ✅ merge (params 우선)
    }

    // body가 비어있으면 경고(상세 다운로드에서 params 누락 방지)
    if (!body || Object.keys(body).length === 0) {
      throw new Error("Request body is empty. Provide params or formSelector+mapping.");
    }

    const url = resolveContextPath(contextPath) + endpoint;
    const res = await postJson(url, body);

    if (!res.ok) {
      const text = await res.text().catch(() => "");
      throw new Error("Request failed: " + res.status + (text ? " / " + text : ""));
    }

    if (responseType === "json") {
      return await res.json();
    }

    const blob = await res.blob();
    downloadBlob(blob, downloadFilename);
    return true;
  }

  // ✅ 사전통지서 전용 래퍼(얇게)
  async function downloadFineAdvanceNotice(evId, opts) {
    if (!evId) throw new Error("evId is required");
    return excelDownload({
      endpoint: "/eventList/excelDownloadDetail",
      params: { ev_id: evId },   // 서버 키에 맞춤
      responseType: "blob",
      downloadFilename: "과태료부과_사전통지서.xlsx",
      ...(opts || {}),
    });
  }

  global.ExcelDownloader = { excelDownload, downloadFineAdvanceNotice };
})(window);
