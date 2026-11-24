// Command seed-local prepares the local e2e stack's UM database for a POS
// sign-in: System POS for Client 000 and one ACTIVE user per role, each with
// a password. The names and passwords are written only to the env file given
// by -env-file; nothing secret is printed.
//
// The documents follow um-api's model.User and model.System (collections
// "users" and "systems"); passwords are bcrypt at bcrypt.DefaultCost, as
// um-api's utils.HashPassword makes them. Running it again keeps every
// password the env file already holds and the stored hash verifies, so runs
// may overlap; only a missing user or a password that does not verify gets a
// new one, and only then is the env file rewritten.
package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"os"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"golang.org/x/crypto/bcrypt"
)

const (
	clientID     = "000"
	systemCode   = "POS"
	systemName   = "Devper POS"
	statusActive = "ACTIVE"
	seedTimeout  = 20 * time.Second
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
	known, err := readEnvFile(opts.envFile)
	if err != nil {
		return err
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
	rotatedAny := false
	for _, u := range users {
		password, rotated, err := upsertUser(ctx, db, u, knownPassword(known, u))
		if err != nil {
			return err
		}
		rotatedAny = rotatedAny || rotated
		lines = append(lines, u.envPrefix+"_USERNAME="+u.username, u.envPrefix+"_PASSWORD="+password)
	}
	if !rotatedAny {
		fmt.Println("seed-local: kept the existing passwords")
		return nil
	}
	fmt.Println("seed-local: generated new passwords")
	return writeEnvFileAtomically(opts.envFile, lines)
}

// knownPassword is u's password in the env file, if the file names u.
func knownPassword(known map[string]string, u seededUser) string {
	if known[u.envPrefix+"_USERNAME"] != u.username {
		return ""
	}
	return known[u.envPrefix+"_PASSWORD"]
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

// storedHash is u's password hash in the database, or "" when u is not there.
func storedHash(ctx context.Context, db *mongo.Database, u seededUser) (string, error) {
	var doc struct {
		Password string `bson:"password"`
	}
	err := db.Collection("users").FindOne(ctx, bson.M{"username": u.username}).Decode(&doc)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return "", nil
	}
	if err != nil {
		return "", fmt.Errorf("find user %s: %w", u.username, err)
	}
	return doc.Password, nil
}

// upsertUser makes u an ACTIVE user of Client 000, keeping [known] as its
// password when the stored hash verifies it, and returns the password and
// whether it changed.
func upsertUser(ctx context.Context, db *mongo.Database, u seededUser, known string) (string, bool, error) {
	hash, err := storedHash(ctx, db, u)
	if err != nil {
		return "", false, err
	}
	password, rotated, err := choosePassword(known, hash, generatePassword)
	if err != nil {
		return "", false, err
	}
	now := time.Now()
	set := bson.M{
		"firstName": u.firstName, "lastName": "", "clientId": clientID,
		"role": u.role, "status": statusActive, "phone": "", "email": "",
		"updatedBy": primitive.NilObjectID, "updatedDate": now,
	}
	if rotated {
		newHash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
		if err != nil {
			return "", false, fmt.Errorf("hash password of %s: %w", u.username, err)
		}
		set["password"] = string(newHash)
	}
	update := bson.M{
		"$set":         set,
		"$setOnInsert": bson.M{"_id": primitive.NewObjectID(), "createdBy": primitive.NilObjectID, "createdDate": now},
	}
	filter := bson.M{"username": u.username}
	if _, err := db.Collection("users").UpdateOne(ctx, filter, update, options.Update().SetUpsert(true)); err != nil {
		return "", false, fmt.Errorf("upsert user %s: %w", u.username, err)
	}
	return password, rotated, nil
}
