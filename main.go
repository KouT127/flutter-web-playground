package main

import (
	"encoding/json"
	"fmt"
	_ "github.com/KouT127/todo-sample/statik"
	"github.com/go-chi/chi"
	"github.com/go-chi/chi/middleware"
	"github.com/rakyll/statik/fs"
	"log"
	"net/http"
)

type TaskList []Task

type Task struct {
	ID      int    `json:"id"`
	Title   string `json:"title"`
	Content string `json:"content"`
}

var (
	taskList TaskList
)

func main() {
	addr := 8080
	r := chi.NewRouter()
	r.Use(middleware.Recoverer)
	r.Use(middleware.Logger)
	r.Get("/tasks", func(w http.ResponseWriter, r *http.Request) {
		tasks := map[string]TaskList{
			"task_list": taskList,
		}
		bytes, err := json.Marshal(tasks)
		if err != nil {
			w.WriteHeader(http.StatusBadRequest)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(bytes))
	})

	r.Post("/tasks", func(w http.ResponseWriter, r *http.Request) {
		var (
			task Task
		)
		if err := json.NewDecoder(r.Body).Decode(&task); err != nil {
			w.WriteHeader(http.StatusBadRequest)
			return
		}
		taskList = append(taskList, task)
		w.Header().Set("Content-Type", "application/json")
		bytes, err := json.Marshal(task)
		if err != nil {
			w.WriteHeader(http.StatusBadRequest)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(bytes))
	})
	fs, err := fs.New()
	if err != nil {
		log.Fatal(err)
	}
	r.Handle("/*", http.StripPrefix("", http.FileServer(fs)))
	fmt.Printf("Started server %d \n", addr)
	http.ListenAndServe(fmt.Sprintf(":%d", addr), r)
}
