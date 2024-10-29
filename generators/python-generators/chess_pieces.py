from enum import Enum

class ChessPiece(Enum):
    KING = 1
    QUEEN = 2
    ROOK = 3
    BISHOP = 4
    KNIGHT = 5
    PAWN = 6

    def __str__(self):
        return self.name

    def __repr__(self):
        return self.name

class Move(object):
    def __init__(self, col_offset, row_offset):
        self.col_offset = col_offset
        self.row_offset = row_offset

def moves(piece):
    pass # TODO: implement this