#!/usr/bin/env python3
__author__ = 'Austin Matthews'

'''
Tic-Tac-Toe

Plays the game of tic-tac-toe against a human opponent
'''

import sys

# global constants
X = "X"
O = "O"
empty = " "
tie = "TIE"
num_squares = 9

def new_board():
    """Create new game board."""
    board = []
    for square in range(num_squares):
        board.append(empty)
    return board


def display_instruct():
    """Display game instructions."""
    print(
    """
    Welcome to the greatest intellectual challenge of all time: Tic-Tac-Toe.
    This will be a showdown between your human brain and my silicon processor.

    You will make your move known by entering a number, 0 - 8.
    The number will correspond to the board position as illustrated:

                    0 | 1 | 2
                    ---------
                    3 | 4 | 5
                    ---------
                    6 | 7 | 8

    Prepare yourself, human.  The ultimate battle is about to begin.
    """
    )


def display_short_instruct():
    """Display short version of game instructions."""
    print(
    """Enter a number, 0 - 8, corresponding to the board position as illustrated:

     0 | 1 | 2
     ---------
     3 | 4 | 5
     ---------
     6 | 7 | 8
     """
    )
    print("Current board in-play: ")


def ask_yes_no(question):
    """Ask a yes or no question."""
    response = None
    while response not in ("y", "n"):
        response = input(question).lower()
    return response


def pieces():
    """Determine if player or computer goes first."""
    go_first = ask_yes_no("Does the human want the first move? (y/n): ")
    if go_first == "y":
        print("\nPlease have the first move ... we both know you will need it")
        human = X
        computer = O
    else:
        print("\nbravery will be your undoing ... I shall go first")
        computer = X
        human = O
    return computer, human


def display_board(board):
    """Display game board on screen."""
    print("\n\t", board[0], "|", board[1], "|", board[2])
    print("\t", "---------")
    print("\t", board[3], "|", board[4], "|", board[5])
    print("\t", "---------")
    print("\t", board[6], "|", board[7], "|", board[8], "\n")


def ask_number(question, low, high, board):
    """Ask for a number within a range."""
    response = None
    while response not in range(low, high):
        if response == '':
            print("\nTry again, input is required and it must be an integer.\n")
            display_short_instruct()
            display_board(board)
            #sys.exit()
        try:
            response = int(input(question))
        except ValueError:
            print("\nTry again, input must be an integer.\n")
            display_short_instruct()
            display_board(board)
    return response


def legal_moves(board):
    """Create list of legal moves."""
    moves = []
    for square in range(num_squares):
        if board[square] == empty:
            moves.append(square)
    return moves


def winner(board):
    """Determine the game winner."""
    ways_to_win = ((0, 1, 2),
                   (3, 4, 5),
                   (6, 7, 8),
                   (0, 3, 6),
                   (1, 4, 7),
                   (2, 5, 8),
                   (0, 4, 8),
                   (2, 4, 6))

    for row in ways_to_win:
        if board[row[0]] == board[row[1]] == board[row[2]] != empty:
            final_winner = board[row[0]]
            return final_winner

    if empty not in board:
        return tie

    return None


def human_move(board, human):
    """Get human move."""
    legal = legal_moves(board)
    move = None
    while move not in legal:
        move = ask_number("Where would the human like to move? (0 - 8): ", 0, num_squares, board)
        if move not in legal:
            print("\nThat square is already occupied, foolish human.  Choose another.\n")
            display_short_instruct()
            display_board(board)
    print("updating board ...")
    return move


def computer_move(board, computer, human):
    """Make computer move."""
    # make a copy to work with since function will be changing list
    board = board[:]
    # the best positions to have, in order
    best_moves = (4, 0, 2, 6, 8, 1, 3, 5, 7)

    print("The computer takes square number", end=" ")

    # if computer can win, take that move
    for move in legal_moves(board):
        board[move] = computer
        if winner(board) == computer:
            print(move)
            return move
        # done checking this move, undo it
        board[move] = empty

    # if human can win, block that move
    for move in legal_moves(board):
        board[move] = human
        if winner(board) == human:
            print(move)
            return move
        # done checking this move, undo it
        board[move] = empty

    # since no one can win on next move, pick best open square
    for move in best_moves:
        if move in legal_moves(board):
            print(move)
            return move


def next_turn(turn):
    """Switch turns."""
    if turn == X:
        return O
    else:
        return X


def congrat_winner(the_winner, computer, human):
    """Congratulate the winner."""
    if the_winner != tie:
        print(the_winner, "won!\n")
    else:
        print("ANOTHER TIE!\n")

    if the_winner == computer:
        print("As I predicted, human, I am triumphant once more.\n\nProof that computers are superior to humans in all regards.\n")

    elif the_winner == human:
        print("No, no!  It cannot be!  Somehow you tricked me, human.\n\nBut never again!  I, the computer, so swear it!\n")

    elif the_winner == tie:
        print("You were most lucky, human, and somehow managed to tie me.\n\nCelebrate now ... for this is the best you will ever achieve.\n")

    # ask to play another game when one ends
    try_again = ask_yes_no("Shall we play a game? (y/n): ")
    if try_again == "n":
        sys.exit()
    else:
        main()


def main():
    display_instruct()
    computer, human = pieces()
    turn = X
    board = new_board()
    display_board(board)

    while not winner(board):
        if turn == human:
            move = human_move(board, human)
            board[move] = human
        else:
            move = computer_move(board, computer, human)
            board[move] = computer
        display_board(board)
        turn = next_turn(turn)

    the_winner = winner(board)
    congrat_winner(the_winner, computer, human)

# start the program
main()