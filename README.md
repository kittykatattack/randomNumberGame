Number Guessing Game in Elm
===========================

This is a simple number guessing game, which is a good example of how to
use Elm to create a basic program with user input, information processing and
output. [Click here to play the game.](https://gitcdn.xyz/repo/kittykatattack/numberGuessingGame/master/index.html)

This code requires a familiarity with Elm using the `StartApp`
architecture, and a level of understanding up to about Example #5 in
the Elm Architecture examples.

Structure
--------

The Number Guessing Game is made up of two modules: `Main.elm` and
`Game.elm`. `Main.elm` just consists of the basic `StartApp` code that
wires together the application. The game program exists entirely in the
`Game.elm` module. It's composed of the 3 standard Elm Architecture
units: Model, Update and View

Model
-----

An important feature of this game is that tagged unions are used to
figure out the `GameState`. The game can have 4 possible states:
`Started`, `Lost`, `Won` and `InProgress`. Here's how they're
defined:
```elm
type GameState 
  = Started 
  | Lost
  | Won
  | InProgress
```
As you'll soon see, the `update` function is going to analyze the
model data to figure out which of these states is currently active.

All the important game variables are stored in the `model`:
```elm
type alias Model = 
  { mysteryNumber : Int
  , maxGuesses : Int
  , guessesMade : Int
  , gameState : GameState
  , inputValue : Int
  }

init : (Model, Effects Action)
init =
  ({ mysteryNumber = 50
   , maxGuesses = 10
   , guessesMade = 0
   , gameState = Started
   , inputValue = 0
   }
   , Effects.none
  )
```
You can see that `gameState` is used to help track the current state
of the game. It's initialized to `Started` when the game starts.

`mysteryNumber` is the number that the player has to guess. `maxGuesses` 
is the maximum number of guesses that the player is allowed to make before the game
ends. `guessesMade` is used to track how many guessed the player has
made.

`inputValue` is an interesting one! It actually represents the number that 
the player will type into the HTML text input field. You'll see ahead
how the code captures this value from the text field and copies it
into the model.

Update
------

The `update` function processes three actions:
```elm
type Action
  = Guess 
  | Restart
  | EnterText String
```

- `Guess`: An action that runs each time the player presses the guess
    button
- `EnterText`: An action that runs each time the player enters any
    text in the HTML input field.
- `Restart`: An action that runs when the game is restarted.

###The Guess Action

Each time the player presses the button, the `Guess` action runs. It
does two things:

1. Sets the model's `gameState` to `Lost`, `Won` or `InProgress`
   depending on whether or not the player has guess the correct number
   and still has guesses left.

2. Updates the number of `guessesMade` by one. 

```elm
Guess ->

  let
    
    -- `checkGameState` tells you if the game is InProgress, Lost or Won 
           
    checkGameState model =
      if model.guessesMade >= model.maxGuesses && model.inputValue /= model.mysteryNumber
         then
           Lost

      else if model.guessesMade <= model.maxGuesses && model.inputValue == model.mysteryNumber 
          then
            Won

      else InProgress
  in

  ( { model 

      -- Update the guessesRemaining and guessesMade

      | guessesMade = model.guessesMade + 1

      -- Check the state of the game

      , gameState = checkGameState model
    }
    , Effects.none
  )

```

###The EnterText action

Whenever the player enters text into the input field, the `EnterText`
action runs.

```elm
EnterText inputValue ->
  ( { model | inputValue =
        String.toInt inputValue 
          |> Result.toMaybe 
          |> Maybe.withDefault 0 
    }
    , Effects.none
  )
```
Its job is to convert the input field's string value to an integer,
and provide a default value of `0` in case the conversion operation
fails for some reason.

###The Restart action

The last action, `Restart` just resets the game. The will happen if
the player presses the restart button after the game is finished.
```elm
Restart ->
  init 
```
All it does is re-initialize the model to its original values so that
the player can play again.

View
----

The View is `<div>` tag that contains the game message text, the input
text field, and the button that let's the player make a guess.
```elm
view : Signal.Address Action -> Model -> Html
view address model =
  div
    []
    [ messageDisplay model       -- The game message text
    , inputField address         -- The input field
    , guessButton address model  -- The button
    ]
```
Each of these UI elements is created by functions, which are explained
next.

###The button

The `guessButton` function displays a different label, and performs a
different action depending on the state of the game. If the game is `Started`, or 
`InProgress` the label displays "guess" and runs the `Guess` action.
If the game is `Won` or `Lost`, the button label displays "restart"
and runs the `Restart` action.
```elm
guessButton address model =
  if model.gameState == Started 
  || model.gameState == InProgress 
  then
    button [ onClick address Guess ] [ text "guess" ]

  else
    button [ onClick address Restart ] [ text "restart" ]
```

###The text input field
The `inputField` function displays "Enter a number..." as the text
field's placeholder. Only numbers can be entered. Whenever the player inputs text, the `EnterText`
action runs.
```elm
inputField address = 
  input
    [ placeholder "Enter a number..."
    , type' "number"
    , on "change" targetValue (Signal.message address << EnterText)
    ]
    []
```

###The game state message

The `gameMessage` function is the most complex. It displays a
different message depending on the state of the game. It also contains a
sub-function called `stateMessage` which tells the player what his/her
guess was, the game state and the mystery number. If the game has been `Started` or 
is `InProgress`, then current guess number and the maximum number of
allowable guesses are also displayed.
```elm
gameMessage model =
  let
    stateMessage model =
      " Your guess: "
      ++ toString model.inputValue
      ++ ", State: "
      ++ toString model.gameState
      ++ ", Mystery Number: "
      ++ toString model.mysteryNumber
      ++ if model.gameState == Started || model.gameState == InProgress then
           ", Guess Number: " 
           ++ toString model.guessesMade 
           ++ ", Max Guesses:  " 
           ++ toString model.maxGuesses
         else
           ""
  in
    case model.gameState of
      Started -> 
        "I am thinking of a number between 1 and 100." ++ stateMessage model

      InProgress ->
        if model.inputValue < model.mysteryNumber then
          "That's too low." ++ stateMessage model

        else 
          "That's too high." ++ stateMessage model

      Lost ->
        "You've run out of guesses! The mystery number was: "
        ++ toString model.mysteryNumber
        ++ ". "
        ++ "Game Over!" ++ stateMessage model

      Won ->
        "That's correct! It took you: "
        ++ toString model.guessesMade
        ++ " guesses. "
        ++ "Game Over!" ++ stateMessage model

```

