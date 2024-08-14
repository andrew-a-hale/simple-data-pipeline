package main

import (
	"database/sql"
	"encoding/json"
	"io"
	"log"
	"log/slog"
	"net/http"
	"os"
	"time"

	"github.com/guregu/null/v5"
	duckdb "github.com/marcboeker/go-duckdb"
)

func newConnection() *duckdb.Connector {
	if os.Getenv("DB_PATH") == "" {
		log.Fatal("Missing ENV VAR: DB_PATH")
	}

	if _, err := os.Stat(os.Getenv("DB_PATH")); err != nil {
		log.Fatal("Missing Database")
	}

	connector, err := duckdb.NewConnector(os.Getenv("DB_PATH"), nil)
	if err != nil {
		log.Fatalf("Failed to create database connector: %v", err)
	}

	return connector
}

type season struct {
	Year int    `json:"year"`
	Id   string `json:"id"`
}

func getSeasons(logger *slog.Logger, w http.ResponseWriter, r *http.Request) {
	db := sql.OpenDB(newConnection())
	defer db.Close()

	rows, err := db.Query("select id, year from seasons")
	if err != nil {
		logger.Error("Failed to read from table seasons")
	}

	var ss []season
	for rows.Next() {
		var s season
		err = rows.Scan(&s.Id, &s.Year)
		if err != nil {
			logger.Error("Failed to read a row from table seasons")
		}
		ss = append(ss, s)
	}

	seasons, err := json.Marshal(ss)
	if err != nil {
		logger.Error("Failed to create JSON Response for seasons")
	}

	w.Write(seasons)
}

type event struct {
	Name     string `json:"name"`
	SName    string `json:"sname"`
	Id       string `json:"id"`
	SeasonId string `json:"season_id"`
}

func getEvents(logger *slog.Logger, w http.ResponseWriter, r *http.Request) {
	db := sql.OpenDB(newConnection())
	defer db.Close()

	seasonId := r.URL.Query().Get("season_id")
	rows, err := db.Query(
		"select name, sname, id, season_id from events where season_id = ?",
		seasonId,
	)
	if err != nil {
		logger.Error("Failed to read from table events")
	}

	var es []event
	for rows.Next() {
		var e event
		err = rows.Scan(&e.Name, &e.SName, &e.Id, &e.SeasonId)
		if err != nil {
			logger.Error("Failed to read a row from table events")
		}
		es = append(es, e)
	}

	events, err := json.Marshal(es)
	if err != nil {
		logger.Error("Failed to create JSON Response for events")
	}

	if len(es) == 0 {
		logger.LogAttrs(
			r.Context(),
			slog.LevelInfo,
			"No Event Found",
			slog.Attr{Key: "seasonId", Value: slog.StringValue(seasonId)},
		)
		events = []byte("[]")
	}

	w.Write(events)
}

type category struct {
	Name     string `json:"name"`
	Id       string `json:"id"`
	SeasonId string `json:"season_id"`
	EventId  string `json:"event_id"`
}

func getCategories(logger *slog.Logger, w http.ResponseWriter, r *http.Request) {
	db := sql.OpenDB(newConnection())
	defer db.Close()

	eventId := r.URL.Query().Get("event_id")
	rows, err := db.Query(
		"select name, id, season_id, event_id from categories where event_id = ?",
		eventId,
	)
	if err != nil {
		log.Fatal("Failed to read from table categories")
	}

	var cs []category
	for rows.Next() {
		var c category
		err = rows.Scan(&c.Name, &c.Id, &c.SeasonId, &c.EventId)
		if err != nil {
			log.Fatal("Failed to read a row from table categories")
		}
		cs = append(cs, c)
	}

	categories, err := json.Marshal(cs)
	if err != nil {
		log.Fatal("Failed to create JSON Response for categories")
	}

	if len(cs) == 0 {
		logger.LogAttrs(
			r.Context(),
			slog.LevelInfo,
			"No Category Found",
			slog.Attr{
				Key:   "eventId",
				Value: slog.StringValue(eventId),
			},
		)
		categories = []byte("[]")
	}

	w.Write(categories)
}

type session struct {
	Name       string `json:"name"`
	Id         string `json:"id"`
	SeasonId   string `json:"season_id"`
	EventId    string `json:"event_id"`
	CategoryId string `json:"category_id"`
}

func getSessions(logger *slog.Logger, w http.ResponseWriter, r *http.Request) {
	db := sql.OpenDB(newConnection())
	defer db.Close()

	eventId := r.URL.Query().Get("event_id")
	categoryId := r.URL.Query().Get("category_id")
	rows, err := db.Query(
		"select name, id, season_id, event_id, category_id from sessions where event_id = ? and category_id = ?",
		eventId,
		categoryId,
	)
	if err != nil {
		logger.Error("Failed to read from table sessions")
	}

	var ss []session
	for rows.Next() {
		var s session
		err = rows.Scan(&s.Name, &s.Id, &s.SeasonId, &s.EventId, &s.CategoryId)
		if err != nil {
			logger.Error("Failed to read a row from table sessions")
		}
		ss = append(ss, s)
	}

	sessions, err := json.Marshal(ss)
	if err != nil {
		logger.Error("Failed to create JSON Response for sessions")
	}

	if len(ss) == 0 {
		logger.LogAttrs(
			r.Context(),
			slog.LevelInfo,
			"No Session Found",
			slog.Attr{
				Key:   "eventId",
				Value: slog.StringValue(eventId),
			},
			slog.Attr{
				Key:   "categoryId",
				Value: slog.StringValue(categoryId),
			},
		)
		sessions = []byte("[]")
	}

	w.Write(sessions)
}

type classification struct {
	Name       string   `json:"name"`
	Number     null.Int `json:"number"`
	Position   null.Int `json:"position"`
	Points     int      `json:"points"`
	SeasonId   string   `json:"season_id"`
	EventId    string   `json:"event_id"`
	CategoryId string   `json:"category_id"`
	SessionId  string   `json:"session_id"`
}

func getClassification(logger *slog.Logger, w http.ResponseWriter, r *http.Request) {
	db := sql.OpenDB(newConnection())
	defer db.Close()

	sessionId := r.URL.Query().Get("session_id")
	rows, err := db.Query(
		"select name, number, position, points, season_id, event_id, category_id, session_id from classifications where session_id = ?",
		sessionId,
	)
	if err != nil {
		logger.Error("Failed to read from table classifications: %v", err)
	}

	var cs []classification
	for rows.Next() {
		var c classification
		err = rows.Scan(&c.Name, &c.Number, &c.Position, &c.Points, &c.SeasonId, &c.EventId, &c.CategoryId, &c.SessionId)
		if err != nil {
			logger.Error("Failed to read a row from table classifications: %v", err)
		}
		cs = append(cs, c)
	}

	classification, err := json.Marshal(cs)
	if err != nil {
		logger.Error("Failed to create JSON Response for classification")
	}

	if len(cs) == 0 {
		logger.LogAttrs(
			r.Context(),
			slog.LevelInfo,
			"No Classification Found",
			slog.Attr{
				Key:   "sessionId",
				Value: slog.StringValue(sessionId),
			},
		)
		classification = []byte("[]")
	}

	w.Write(classification)
}

type Logger struct {
	handler    http.Handler
	logHandler *slog.Logger
}

func (l *Logger) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	start := time.Now()
	l.handler.ServeHTTP(w, r)
	l.logHandler.LogAttrs(
		r.Context(),
		slog.LevelInfo,
		"",
		slog.Attr{Key: "Method", Value: slog.StringValue(r.Method)},
		slog.Attr{Key: "Path", Value: slog.StringValue(r.URL.Path)},
		slog.Attr{Key: "DurationMs", Value: slog.Int64Value(time.Since(start).Milliseconds())},
	)
}

func NewLogger(handler http.Handler, logger *slog.Logger) *Logger {
	return &Logger{handler, logger}
}

func withLogger(logger *slog.Logger, f func(*slog.Logger, http.ResponseWriter, *http.Request)) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		f(logger, w, r)
	}
}

func main() {
	if os.Getenv("PORT") == "" {
		log.Fatal("Missing ENV VAR: PORT")
	}
	port := os.Getenv("PORT")

	logFile, err := os.Create("./server.log")
	if err != nil {
		log.Fatal("Failed to create log file")
	}
	defer logFile.Close()

	handler := slog.NewJSONHandler(
		io.MultiWriter(os.Stdout, logFile),
		&slog.HandlerOptions{Level: slog.LevelInfo},
	)
	logger := slog.New(handler)

	logger.Info("Webserver Started @ Port: " + port)
	defer logger.Info("Webserver Ended!")

	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) { w.Write([]byte("Local Open MotoGP DB")) })
	mux.HandleFunc("/seasons", withLogger(logger, getSeasons))
	mux.HandleFunc("/events", withLogger(logger, getEvents))
	mux.HandleFunc("/categories", withLogger(logger, getCategories))
	mux.HandleFunc("/sessions", withLogger(logger, getSessions))
	mux.HandleFunc("/classification", withLogger(logger, getClassification))
	log.Fatal(http.ListenAndServe(":"+port, NewLogger(mux, logger)))
}
