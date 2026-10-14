package detection

import (
	"bytes"
	"crypto/aes"
	"crypto/cipher"
	"net/http/httptest"
	"testing"
)

func TestEncryptionMatchesJavaCBCFormat(t *testing.T) {
	key := bytes.Repeat([]byte{42}, 32)
	for _, length := range []int{1, 16, 17, 1024} {
		plain := bytes.Repeat([]byte{91}, length)
		encrypted, err := encryptImage(plain, key)
		if err != nil {
			t.Fatal(err)
		}
		again, _ := encryptImage(plain, key)
		if bytes.Equal(encrypted, again) {
			t.Fatal("IV must be random")
		}
		block, _ := aes.NewCipher(key)
		decoded := make([]byte, len(encrypted)-16)
		cipher.NewCBCDecrypter(block, encrypted[:16]).CryptBlocks(decoded, encrypted[16:])
		padding := int(decoded[len(decoded)-1])
		if padding < 1 || padding > 16 || !bytes.Equal(decoded[:len(decoded)-padding], plain) {
			t.Fatal("CBC/PKCS7 round trip failed")
		}
	}
	if _, err := encryptImage([]byte{1}, []byte("short")); err == nil {
		t.Fatal("short keys must fail")
	}
}
func TestUnauthorizedCaptureDoesNotStartCamera(t *testing.T) {
	t.Setenv("H100_TRIGGER_TOKEN", "expected-secret")
	r := httptest.NewRequest("POST", "/detection/trigger", bytes.NewBufferString(`{}`))
	r.Header.Set("Authorization", "Bearer incorrect")
	w := httptest.NewRecorder()
	Handler(w, r)
	if w.Code != 401 {
		t.Fatalf("got %d", w.Code)
	}
}
func TestCaptureBufferBound(t *testing.T) {
	var b boundedBuffer
	if _, err := b.Write(make([]byte, maxImage)); err != nil {
		t.Fatal(err)
	}
	if _, err := b.Write([]byte{1}); err == nil {
		t.Fatal("unbounded capture")
	}
}
