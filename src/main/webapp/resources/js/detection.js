(function () {
    'use strict';
    document.addEventListener('click', async function (event) {
        const button = event.target.closest('.detection-btn');
        if (!button || button.disabled) return;
        button.disabled = true;
        const label = button.textContent;
        button.textContent = '저장 중';
        // Retain the request ID after an uncertain failure so retries cannot duplicate an event.
        if (!button.dataset.requestId) {
            const bytes = crypto.getRandomValues(new Uint8Array(16));
            bytes[6] = (bytes[6] & 15) | 64;
            bytes[8] = (bytes[8] & 63) | 128;
            const hex = Array.from(bytes, b => b.toString(16).padStart(2, '0')).join('');
            button.dataset.requestId = [hex.slice(0,8), hex.slice(8,12), hex.slice(12,16), hex.slice(16,20), hex.slice(20)].join('-');
        }
        try {
            const base = button.dataset.context + '/deviceList/detection';
            const tokenResponse = await fetch(base + '/token', {headers: {'X-Requested-With': 'XMLHttpRequest'}});
            if (!tokenResponse.ok) throw new Error('로그인이 필요합니다.');
            const token = await tokenResponse.json();
            const response = await fetch(base + '/' + button.dataset.deviceId, {
                method: 'POST',
                headers: {'Content-Type': 'application/json', 'X-Requested-With': 'XMLHttpRequest', 'X-H100-CSRF': token.token},
                body: JSON.stringify({request_id: button.dataset.requestId})
            });
            const receipt = await response.json();
            if (!response.ok || !receipt.ok) throw new Error(receipt.msg || '캡처 저장에 실패했습니다.');
            delete button.dataset.requestId;
            button.dataset.eventId = receipt.event_id;
            alert('저장 완료 · 이벤트 ' + receipt.event_id);
        } catch (error) {
            alert(error.message || '캡처 저장에 실패했습니다.');
        } finally {
            button.textContent = label;
            button.disabled = false;
        }
    });
})();
