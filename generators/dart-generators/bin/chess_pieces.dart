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
  // TODO: This
}