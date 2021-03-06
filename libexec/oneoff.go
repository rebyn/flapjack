package main

import (
	"encoding/json"
	"flapjack"
	"fmt"
	"gopkg.in/alecthomas/kingpin.v1"
	"os"
	"strings"
	"time"
)

var (
	entity   = kingpin.Arg("entity", "Entity name").Required().String()
	check    = kingpin.Arg("check", "Check name").Required().String()
	state    = kingpin.Arg("state", "Current state").Required().String()
	summary  = kingpin.Arg("summary", "Summary of event").Required().String()
	debug    = kingpin.Flag("debug", "Enable verbose output (default false)").Bool()
	server   = kingpin.Flag("server", "Redis server to connect to (default localhost:6380)").Default("localhost:6380").String()
	database = kingpin.Flag("database", "Redis database to connect to (default 0)").Int()
)

func main() {
	kingpin.Version("0.0.1")
	kingpin.Parse()

	if *debug {
		fmt.Println("Entity:", *entity)
		fmt.Println("Check:", *check)
		fmt.Println("State:", *state)
		fmt.Println("Summary:", *summary)
		fmt.Println("Debug:", *debug)
		fmt.Println("Server:", *server)
		fmt.Println("Database:", *database)
	}

	addr := strings.Split(*server, ":")
	if len(addr) != 2 {
		fmt.Println("Error: invalid address specified:", *server)
		fmt.Println("Should be in format `addr:port` (e.g. 127.0.0.1:6380)")
		os.Exit(1)
	}

	event := flapjack.Event{
		Entity:  *entity,
		Check:   *check,
		Type:    "service",
		State:   *state,
		Summary: *summary,
		Time:    time.Now().Unix(),
	}

	if *debug {
		data, _ := json.Marshal(event)
		fmt.Printf("Event data: %s\n", data)
	}

	transport, err := flapjack.Dial(*server, *database)
	if *debug {
		fmt.Printf("Transport: %+v\n", transport)
	}
	if err != nil {
		fmt.Println("Error: couldn't connect to Redis:", err)
		os.Exit(1)
	}

	reply, err := transport.Send(event)
	if *debug {
		fmt.Println("Reply from Redis:", reply)
	}
	if err != nil {
		fmt.Println("Error: couldn't send event:", err)
		os.Exit(1)
	}
}
