#!/bin/bash
# freeCodeCamp Number Guessing Game

# PSQL command for this project
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Ask for username
echo "Enter your username:"
read USERNAME

# Look up user_id
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME';")

# If user does not exist
if [[ -z $USER_ID ]]
then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  USER_ID=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME') RETURNING user_id;")
else
  # Existing user: get games_played and best_game
  USER_STATS=$($PSQL "SELECT COUNT(game_id), MIN(guesses) FROM games WHERE user_id = $USER_ID;")
  IFS="|" read GAMES_PLAYED BEST_GAME <<< "$USER_STATS"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Generate secret number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
NUMBER_OF_GUESSES=0

# First prompt to guess
echo "Guess the secret number between 1 and 1000:"

# Loop until guess is correct
while true
do
  read GUESS

  # Validate integer
  if ! [[ $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    continue
  fi

  NUMBER_OF_GUESSES=$(( NUMBER_OF_GUESSES + 1 ))

  if (( GUESS < SECRET_NUMBER ))
  then
    echo "It's higher than that, guess again:"
  elif (( GUESS > SECRET_NUMBER ))
  then
    echo "It's lower than that, guess again:"
  else
    break
  fi
done

# Save game result
$PSQL "INSERT INTO games(user_id, guesses) VALUES($USER_ID, $NUMBER_OF_GUESSES);" > /dev/null

# Final message
echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
