enum ChessPiece {
  PAWN,
  KNIGHT,
  BISHOP,
  ROOK,
  QUEEN,
  KING
}

class Move {
  Move(this.column_offset, this.row_offset);

  final int column_offset;
  final int row_offset;
}

Iterable<Move> generateMoves(ChessPiece piece) sync* {
  switch (piece){
    case ChessPiece.PAWN: 
      yield Move(0, 1); // Move forward
      yield Move(0, 2); // Move forward (2) (only applicable at start)
      yield Move(1, 1); // Capture diagonally right
      yield Move(-1, 1); // Capture diagonally left
      break;
    case ChessPiece.KNIGHT:
      yield Move(1, 2); // L-shape move
      yield Move(2, 1); // L-shape move
      yield Move(1, -2); // L-shape move
      yield Move(2, -1); // L-shape move
      yield Move(-1, 2); // L-shape move
      yield Move(-2, 1); // L-shape move
      yield Move(-1, -2); // L-shape move
      yield Move(-2, -1); // L-shape move
      break;
    case ChessPiece.BISHOP:
      for (int i = 1; i < 8; i++) {
        yield Move(i, i); // Move diagonally right down
        yield Move(-i, -i); // Move diagonally left up
        yield Move(i, -i); // Move diagonally right up
        yield Move(-i, i); // Move diagonally left down
      }
      break;
    case ChessPiece.ROOK:
      for (int i = 1; i < 8; i++) {
        yield Move(i, 0); // Move right
        yield Move(-i, 0); // Move left
        yield Move(0, i); // Move down
        yield Move(0, -i); // Move up
      }
      break;
    case ChessPiece.QUEEN:
      generateMoves(ChessPiece.BISHOP); // Diagonal moves
      generateMoves(ChessPiece.ROOK); // Straight moves
      break;
    case ChessPiece.KING:
      yield Move(1, 0); // Move right
      yield Move(-1, 0); // Move left
      yield Move(0, 1); // Move down
      yield Move(0, -1); // Move up
      yield Move(1, 1); // Move diagonally right down
      yield Move(-1, -1); // Move diagonally left up
      yield Move(1, -1); // Move diagonally right up
      yield Move(-1, 1); // Move diagonally left down
      break;
  }
}

class Location {
  Location(this.column, this.row);

  final int column;
  final int row;

  operator +(Move move) {
    return Location(column + move.column_offset, row + move.row_offset);
  }
}

class Game {
  Iterable<Move> realMoves(ChessPiece piece, Location location, int player) sync* {
    for (final m in generateMoves(piece)){
      final Location(column: c, row: r) = location + m;
      if (c >= 0 && c < 8 && r >= 0 && r < 8) {
        yield m;
      }
    }
  }
}