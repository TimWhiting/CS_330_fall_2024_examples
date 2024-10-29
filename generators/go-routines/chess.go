package main

import "fmt"

type Move struct {
	column_offset int
	row_offset    int
}

const (
	King   = 0
	Queen  = 1
	Rook   = 2
	Bishop = 3
	Knight = 4
	Pawn   = 5
)

func generate_moves(piece int, moves chan Move) {
	// TODO: This
}

func main() {
	moves := make(chan Move)
	go generate_moves(King, moves)
	fmt.Println("Hello, World!")
}
