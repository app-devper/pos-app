package main

import (
	"errors"
	"os"
	"path/filepath"
	"testing"

	"golang.org/x/crypto/bcrypt"
)

func hashOf(t *testing.T, password string) string {
	t.Helper()
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.MinCost)
	if err != nil {
		t.Fatal(err)
	}
	return string(hash)
}

func fixed(password string) func() (string, error) {
	return func() (string, error) { return password, nil }
}

func TestChoosePassword(t *testing.T) {
	stored := hashOf(t, "known-password")
	tests := []struct {
		name        string
		known       string
		storedHash  string
		wantPass    string
		wantRotated bool
	}{
		{"keeps a known password the stored hash verifies", "known-password", stored, "known-password", false},
		{"rotates when the known password does not verify", "other-password", stored, "new-password", true},
		{"rotates when no password is known", "", stored, "new-password", true},
		{"rotates when the user is not stored yet", "known-password", "", "new-password", true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, rotated, err := choosePassword(tt.known, tt.storedHash, fixed("new-password"))
			if err != nil {
				t.Fatal(err)
			}
			if got != tt.wantPass || rotated != tt.wantRotated {
				t.Errorf("got (%q, %v), want (%q, %v)", got, rotated, tt.wantPass, tt.wantRotated)
			}
		})
	}
}

func TestChoosePasswordReportsAGenerationFailure(t *testing.T) {
	_, _, err := choosePassword("", "", func() (string, error) { return "", errors.New("no entropy") })
	if err == nil {
		t.Fatal("want an error")
	}
}

func TestParseEnv(t *testing.T) {
	got := parseEnv("# comment\n\nA=1\nB = x=y \nnot a pair\n")
	if len(got) != 2 || got["A"] != "1" || got["B"] != "x=y" {
		t.Errorf("got %v", got)
	}
}

func TestReadEnvFileOfAMissingFileIsEmpty(t *testing.T) {
	got, err := readEnvFile(filepath.Join(t.TempDir(), "missing"))
	if err != nil || len(got) != 0 {
		t.Errorf("got %v, %v", got, err)
	}
}

func TestWriteEnvFileAtomicallyWritesOwnerOnlyLines(t *testing.T) {
	path := filepath.Join(t.TempDir(), ".env.e2e.local")
	if err := writeEnvFileAtomically(path, []string{"A=1", "B=2"}); err != nil {
		t.Fatal(err)
	}
	data, err := os.ReadFile(path)
	if err != nil || string(data) != "A=1\nB=2\n" {
		t.Errorf("got %q, %v", data, err)
	}
	info, err := os.Stat(path)
	if err != nil || info.Mode().Perm() != 0o600 {
		t.Errorf("mode %v, %v", info.Mode().Perm(), err)
	}
}

func TestGeneratePasswordIsLongAndVaries(t *testing.T) {
	a, errA := generatePassword()
	b, errB := generatePassword()
	if errA != nil || errB != nil || len(a) != passwordLength || a == b {
		t.Errorf("lengths %d/%d, equal %v", len(a), len(b), a == b)
	}
}
