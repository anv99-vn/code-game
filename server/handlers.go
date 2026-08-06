package main

import (
	"context"
	"encoding/json"
	"errors"
	"regexp"
)

type Handlers struct {
	Store *Store
	Auth  *Auth
}

// request is one client message over TCP.
type request struct {
	Type string          `json:"type"`
	ID   int64           `json:"id,omitempty"`
	Data json.RawMessage `json:"data,omitempty"`
}

// response is the reply sent back to the client. ID echoes the request ID.
type response struct {
	Type string `json:"type"`
	ID   int64  `json:"id,omitempty"`
	Data any    `json:"data,omitempty"`
}

type errorBody struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

type credentialsData struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type authResponse struct {
	Token    string `json:"token"`
	Username string `json:"username"`
}

var usernameRe = regexp.MustCompile(`^[a-zA-Z0-9_]{3,32}$`)

// dispatch routes a request to the matching handler and builds the response.
func (h *Handlers) dispatch(req request) response {
	switch req.Type {
	case "health":
		return response{Type: "health_ok", ID: req.ID, Data: map[string]string{"status": "ok"}}
	case "register":
		return h.handleRegister(req)
	case "login":
		return h.handleLogin(req)
	case "me":
		return h.handleMe(req)
	default:
		return errorResp(req.ID, "unknown_type", "unknown request type")
	}
}

func errorResp(id int64, code, message string) response {
	return response{Type: "error", ID: id, Data: errorBody{Code: code, Message: message}}
}

func (h *Handlers) tokenResp(id int64, respType, username string) response {
	token, err := h.Auth.IssueToken(username)
	if err != nil {
		return errorResp(id, "internal", "failed to issue token")
	}
	return response{Type: respType, ID: id, Data: authResponse{Token: token, Username: username}}
}

func (h *Handlers) handleRegister(req request) response {
	var data credentialsData
	if err := json.Unmarshal(req.Data, &data); err != nil {
		return errorResp(req.ID, "invalid", "malformed register data")
	}
	if err := validateCredentials(data.Username, data.Password); err != nil {
		return errorResp(req.ID, "invalid", err.Error())
	}
	hash, err := hashPassword(data.Password)
	if err != nil {
		return errorResp(req.ID, "internal", "failed to hash password")
	}
	if err := h.Store.CreateUser(context.Background(), data.Username, hash); err != nil {
		if errors.Is(err, ErrUserExists) {
			return errorResp(req.ID, "user_exists", "username already taken")
		}
		return errorResp(req.ID, "internal", "failed to create user")
	}
	return h.tokenResp(req.ID, "register_ok", data.Username)
}

func (h *Handlers) handleLogin(req request) response {
	var data credentialsData
	if err := json.Unmarshal(req.Data, &data); err != nil {
		return errorResp(req.ID, "invalid", "malformed login data")
	}
	hash, err := h.Store.GetUser(context.Background(), data.Username)
	if err != nil || !checkPassword(hash, data.Password) {
		return errorResp(req.ID, "invalid_credentials", "invalid username or password")
	}
	return h.tokenResp(req.ID, "login_ok", data.Username)
}

func (h *Handlers) handleMe(req request) response {
	var data struct {
		Token string `json:"token"`
	}
	if err := json.Unmarshal(req.Data, &data); err != nil {
		return errorResp(req.ID, "invalid", "malformed me data")
	}
	username, err := h.Auth.ParseToken(data.Token)
	if err != nil {
		return errorResp(req.ID, "invalid_token", "invalid or expired token")
	}
	return response{Type: "me_ok", ID: req.ID, Data: map[string]string{"username": username}}
}

func validateCredentials(username, password string) error {
	if !usernameRe.MatchString(username) {
		return errors.New("username must be 3-32 chars of letters, digits or underscore")
	}
	if len(password) < 8 {
		return errors.New("password must be at least 8 characters")
	}
	if len(password) > 72 {
		return errors.New("password must be at most 72 characters")
	}
	return nil
}
