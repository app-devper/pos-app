package main

import (
	"crypto/rand"
	"fmt"
	"math/big"
	"os"
	"path/filepath"
	"strings"

	"golang.org/x/crypto/bcrypt"
)

const (
	passwordLength = 24
	passwordChars  = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789"
)

// parseEnv reads KEY=value lines; blank lines and # comments are skipped.
func parseEnv(contents string) map[string]string {
	values := map[string]string{}
	for _, line := range strings.Split(contents, "\n") {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		key, value, ok := strings.Cut(line, "=")
		if ok {
			values[strings.TrimSpace(key)] = strings.TrimSpace(value)
		}
	}
	return values
}

// readEnvFile returns the file's values, or none when it does not exist.
func readEnvFile(path string) (map[string]string, error) {
	data, err := os.ReadFile(path)
	if os.IsNotExist(err) {
		return map[string]string{}, nil
	}
	if err != nil {
		return nil, fmt.Errorf("read %s: %w", path, err)
	}
	return parseEnv(string(data)), nil
}

// choosePassword keeps the known password when the stored bcrypt hash
// verifies it, so a run in progress keeps working while another run seeds;
// otherwise (no known password, no stored user, or a mismatch) it generates
// a new one. rotated says whether the stored hash must be replaced.
func choosePassword(known, storedHash string, generate func() (string, error)) (password string, rotated bool, err error) {
	if known != "" && storedHash != "" &&
		bcrypt.CompareHashAndPassword([]byte(storedHash), []byte(known)) == nil {
		return known, false, nil
	}
	password, err = generate()
	if err != nil {
		return "", false, err
	}
	return password, true, nil
}

func generatePassword() (string, error) {
	var b strings.Builder
	limit := big.NewInt(int64(len(passwordChars)))
	for i := 0; i < passwordLength; i++ {
		n, err := rand.Int(rand.Reader, limit)
		if err != nil {
			return "", fmt.Errorf("generate password: %w", err)
		}
		b.WriteByte(passwordChars[n.Int64()])
	}
	return b.String(), nil
}

// writeEnvFileAtomically replaces path in one rename, so a test reading it
// never sees a half-written file.
func writeEnvFileAtomically(path string, lines []string) error {
	tmp, err := os.CreateTemp(filepath.Dir(path), ".env.e2e.tmp-*")
	if err != nil {
		return fmt.Errorf("write %s: %w", path, err)
	}
	defer func() { _ = os.Remove(tmp.Name()) }()
	if err := tmp.Chmod(0o600); err != nil {
		_ = tmp.Close()
		return fmt.Errorf("write %s: %w", path, err)
	}
	if _, err := tmp.WriteString(strings.Join(lines, "\n") + "\n"); err != nil {
		_ = tmp.Close()
		return fmt.Errorf("write %s: %w", path, err)
	}
	if err := tmp.Close(); err != nil {
		return fmt.Errorf("write %s: %w", path, err)
	}
	if err := os.Rename(tmp.Name(), path); err != nil {
		return fmt.Errorf("write %s: %w", path, err)
	}
	return nil
}
