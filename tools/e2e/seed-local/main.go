// Command seed-local prepares the local e2e stack's UM database for a POS
// sign-in: System POS for Client 000 and one ACTIVE user per role, each with
// a freshly generated password. The names and passwords are written only to
// the env file given by -env-file; nothing secret is printed.
//
// The documents follow um-api's model.User and model.System (collections
// "users" and "systems"); passwords are bcrypt at bcrypt.DefaultCost, as
// um-api's utils.HashPassword makes them. Running it again replaces the
// passwords and leaves every other document as it is.
package main

import (
	"context"
	"crypto/rand"
	"errors"
	"flag"
	"fmt"
	"math/big"
	"os"
	"strings"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"golang.org/x/crypto/bcrypt"
)

const (
	clientID       = "000"
	systemCode     = "POS"
	systemName     = "Devper POS"
	statusActive   = "ACTIVE"
	passwordLength = 24
	passwordChars  = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789"
	seedTimeout    = 20 * time.Second
)

// seededUser is one user the e2e suite signs in as.
type seededUser struct {
	envPrefix string
	username  string
	role      string
	firstName string
}

var users = []seededUser{
	{envPrefix: "E2E_ADMIN", username: "e2e-admin", role: "ADMIN", firstName: "E2E Admin"},
	{envPrefix: "E2E_MANAGER", username: "e2e-manager", role: "MANAGER", firstName: "E2E Manager"},
	{envPrefix: "E2E_USER", username: "e2e-user", role: "USER", firstName: "E2E User"},
}

type seedOptions struct {
	mongoURI string
	dbName   string
	posHost  string
	envFile  string
}

func main() {
	opts := parseFlags()
	if err := run(opts); err != nil {
		fmt.Fprintf(os.Stderr, "seed-local: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("seed-local: System %s and %d users of Client %s are ready in %s; credentials in %s\n",
		systemCode, len(users), clientID, opts.dbName, opts.envFile)
}

func parseFlags() seedOptions {
	opts := seedOptions{}
	flag.StringVar(&opts.mongoURI, "mongo", "", "MongoDB URI of the local stack")
	flag.StringVar(&opts.dbName, "db", "e2e_um", "UM database name")
	flag.StringVar(&opts.posHost, "pos-host", "", "pos-api base URL stored as the System's host")
	flag.StringVar(&opts.envFile, "env-file", "", "file that receives the generated credentials")
	flag.Parse()
	return opts
}

func run(opts seedOptions) error {
	if opts.mongoURI == "" || opts.envFile == "" || opts.posHost == "" {
		return errors.New("-mongo, -pos-host and -env-file are required")
	}
	ctx, cancel := context.WithTimeout(context.Background(), seedTimeout)
	defer cancel()
	client, err := mongo.Connect(ctx, options.Client().ApplyURI(opts.mongoURI))
	if err != nil {
		return fmt.Errorf("connect: %w", err)
	}
	defer func() { _ = client.Disconnect(context.Background()) }()
	db := client.Database(opts.dbName)

	if err := upsertSystem(ctx, db, opts.posHost); err != nil {
		return err
	}
	lines := make([]string, 0, 2*len(users))
	for _, u := range users {
		password, err := upsertUser(ctx, db, u)
		if err != nil {
			return err
		}
		lines = append(lines, u.envPrefix+"_USERNAME="+u.username, u.envPrefix+"_PASSWORD="+password)
	}
	return os.WriteFile(opts.envFile, []byte(strings.Join(lines, "\n")+"\n"), 0o600)
}

// upsertSystem gives Client 000 the System POS (um-api model.System), which
// um-api's login checks with GetSystem(clientId, systemCode).
func upsertSystem(ctx context.Context, db *mongo.Database, host string) error {
	now := time.Now()
	filter := bson.M{"clientId": clientID, "systemCode": systemCode}
	update := bson.M{
		"$set": bson.M{"systemName": systemName, "host": host, "updatedDate": now, "updatedBy": primitive.NilObjectID},
		"$setOnInsert": bson.M{
			"_id": primitive.NewObjectID(), "createdDate": now, "createdBy": primitive.NilObjectID,
		},
	}
	_, err := db.Collection("systems").UpdateOne(ctx, filter, update, options.Update().SetUpsert(true))
	if err != nil {
		return fmt.Errorf("upsert system %s: %w", systemCode, err)
	}
	return nil
}

// upsertUser makes u an ACTIVE user of Client 000 with a new password and
// returns that password.
func upsertUser(ctx context.Context, db *mongo.Database, u seededUser) (string, error) {
	password, err := generatePassword()
	if err != nil {
		return "", err
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return "", fmt.Errorf("hash password of %s: %w", u.username, err)
	}
	now := time.Now()
	update := bson.M{
		"$set": bson.M{
			"firstName": u.firstName, "lastName": "", "clientId": clientID, "password": string(hash),
			"role": u.role, "status": statusActive, "phone": "", "email": "",
			"updatedBy": primitive.NilObjectID, "updatedDate": now,
		},
		"$setOnInsert": bson.M{
			"_id": primitive.NewObjectID(), "createdBy": primitive.NilObjectID, "createdDate": now,
		},
	}
	filter := bson.M{"username": u.username}
	if _, err := db.Collection("users").UpdateOne(ctx, filter, update, options.Update().SetUpsert(true)); err != nil {
		return "", fmt.Errorf("upsert user %s: %w", u.username, err)
	}
	return password, nil
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
