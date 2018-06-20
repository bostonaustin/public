package main

import (
	"net"
	"sync"
)

type msg struct {
	Name    string
	Action  int
	msg     string
}

func main() {

	conn := connect()

	go publish("Foo", conn)

	listen(conn)
}


go func() {

}
//reader := bufio.NewReader(os.Stdin)
//s, err := reader.ReadString('\n')
//if err != nil {
//    panic(err)
//
// fmt.Printf(" debug_info: %s\n", s)
}
}
