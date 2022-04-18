package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
)

type handler struct{}

func (h *handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
  if r.URL.RequestURI() == "/healthz" {
    fmt.Fprintf(w, "OK")
  } else if strings.HasPrefix(r.Host, "www.") {
		host := strings.TrimPrefix(r.Host, "www.")
		u := fmt.Sprintf("https://%s%s", host, r.URL.RequestURI())

		http.Redirect(w, r, u, http.StatusMovedPermanently)
	} else {
		http.NotFound(w, r)
	}
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	err := http.ListenAndServe(fmt.Sprintf(":%s", port), new(handler))
	log.Fatal(err)
}
