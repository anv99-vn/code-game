package main

import (
	"bytes"
	"encoding/binary"
	"encoding/json"
	"testing"
)

// TestFrameRoundTrip writes a frame into a buffer and reads it back, verifying
// the length prefix is stripped and the payload decodes to the original value.
func TestFrameRoundTrip(t *testing.T) {
	var buf bytes.Buffer
	msg := map[string]string{"hello": "world"}
	if err := writeFrame(&buf, msg); err != nil {
		t.Fatalf("writeFrame: %v", err)
	}
	frame, err := readFrame(&buf)
	if err != nil {
		t.Fatalf("readFrame: %v", err)
	}
	var got map[string]string
	if err := json.Unmarshal(frame, &got); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	if got["hello"] != "world" {
		t.Errorf("payload = %+v, want hello=world", got)
	}
	if buf.Len() != 0 {
		t.Errorf("buffer not drained: %d bytes left", buf.Len())
	}
}

// TestReadFrameEmptyInput expects readFrame to return an error when the reader
// is empty (closed connection).
func TestReadFrameEmptyInput(t *testing.T) {
	if _, err := readFrame(bytes.NewReader(nil)); err == nil {
		t.Error("expected error reading from empty input")
	}
}

// TestReadFrameTooLarge expects readFrame to reject a declared length above
// maxFrameSize before allocating the payload.
func TestReadFrameTooLarge(t *testing.T) {
	var lb [4]byte
	binary.BigEndian.PutUint32(lb[:], maxFrameSize+1)
	if _, err := readFrame(bytes.NewReader(lb[:])); err == nil {
		t.Error("expected error for oversized frame")
	}
}
