package main

import (
	"encoding/binary"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net"
)

// maxFrameSize caps a single request/response frame at 1 MB.
const maxFrameSize = 1 << 20

// serveConn handles one TCP client connection. Each client sends a stream of
// length-prefixed JSON frames; each request gets exactly one response frame,
// in order.
func (h *Handlers) serveConn(conn net.Conn) {
	defer conn.Close()
	for {
		frame, err := readFrame(conn)
		if err != nil {
			if !errors.Is(err, io.EOF) && !errors.Is(err, io.ErrUnexpectedEOF) {
				log.Printf("read from %s: %v", conn.RemoteAddr(), err)
			}
			return
		}
		var req request
		if err := json.Unmarshal(frame, &req); err != nil {
			_ = writeFrame(conn, errorResp(0, "invalid", "malformed JSON"))
			continue
		}
		if err := writeFrame(conn, h.dispatch(req)); err != nil {
			log.Printf("write to %s: %v", conn.RemoteAddr(), err)
			return
		}
	}
}

// readFrame reads one frame: 4-byte big-endian length followed by the payload.
func readFrame(r io.Reader) ([]byte, error) {
	var lenBuf [4]byte
	if _, err := io.ReadFull(r, lenBuf[:]); err != nil {
		return nil, err
	}
	n := binary.BigEndian.Uint32(lenBuf[:])
	if n > maxFrameSize {
		return nil, fmt.Errorf("frame too large: %d bytes", n)
	}
	frame := make([]byte, n)
	if _, err := io.ReadFull(r, frame); err != nil {
		return nil, err
	}
	return frame, nil
}

// writeFrame writes one frame: 4-byte big-endian length followed by the JSON
// encoded value.
func writeFrame(w io.Writer, v any) error {
	data, err := json.Marshal(v)
	if err != nil {
		return err
	}
	var lenBuf [4]byte
	binary.BigEndian.PutUint32(lenBuf[:], uint32(len(data)))
	if _, err := w.Write(lenBuf[:]); err != nil {
		return err
	}
	_, err = w.Write(data)
	return err
}
