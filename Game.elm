module Game where

import Effects exposing (Effects, Never)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import String
import Time
import Task
import Random exposing (generate, int, initialSeed)
import String.Interpolate exposing (interpolate)

-- MODEL

-- The GameState tracks the current state of the game

type GameState 
  = Started 
  | Lost
  | Won
  | InProgress


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
   , newIntEffect
  )


-- UPDATE

type Action
  = Guess 
  | Restart
  | EnterText String
  | NewMystery Int


newRandIntMB = Signal.mailbox ()


toAction (t, _) = 
  let 
    (newInt, _) = generate (int 1 100) (initialSeed (truncate t))
  in 
    NewMystery newInt


newRandIntSignal = 
  newRandIntMB.signal
  |> Time.timestamp 
  |> Signal.map toAction


newIntEffect = 
  Signal.send newRandIntMB.address ()
  |> Task.map (always (EnterText ""))
  |> Effects.task


-- `intOrZero` converts a string to an integer, with a default value
-- of 0

intOrZero i = String.toInt i |> Result.toMaybe |> Maybe.withDefault 0 


-- `noFx` returns a model without any Effects. It's just a nice way to
-- reduce some boilerplate code

noFx model = (model, Effects.none)


update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    Guess ->

      let
        
        -- `checkGameState` tells you if the game is InProgress, Lost or Won 
               
        checkGameState model =
          case 
            ( model.guessesMade >= model.maxGuesses
            , model.inputValue == model.mysteryNumber
            ) 
          of
            (True, _) -> Lost
            (_, True) -> Won
            _ -> InProgress
      in

      noFx { model 

          -- Update the guessesMade

          | guessesMade = model.guessesMade + 1

          -- Check the state of the game

          , gameState = checkGameState model
        } 

    -- Capture the input value from the text field in the model. This `EnterText`
    -- action is invoked each time the field value changes

    EnterText inputValue -> 
      noFx { model | inputValue = intOrZero inputValue}

    -- Generate a new random integer and use it to update the model's
    -- `mysteryNumber`

    NewMystery newInt -> 
      noFx { model | mysteryNumber = newInt}
      
    -- If the game is restarted, re-initialize the model

    Restart ->
      init 


-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
  div
    []
    [ messageDisplay model
    , inputField address
    , guessButton address model
    ]


-- The <p> tag that displays the game message

messageDisplay model =
  p [] [ text (gameMessage model) ]


-- The <button> that lets the player guess

guessButton address model =
  if model.gameState == Started 
  || model.gameState == InProgress 
  then
    button [ onClick address Guess ] [ text "guess" ]

  else
    button [ onClick address Restart ] [ text "restart" ]


-- The <input> text field. It runs the `EnterText` action whenever
-- the 

inputField address = 
  input
    [ placeholder "Enter a number..."
    , type' "number"
    , on "change" targetValue (Signal.message address << EnterText)
    ]
    []


-- The rest of the following code defines the game display messages 

-- the `gameMessage` function displays the correct game text depending on the
-- state of the game

gameMessage model =
  let
    stateMessage model =
      let 
        stateToString = 
          if model.gameState == Started || model.gameState == InProgress 
          then interpolate 
            ", Guess Number: {0} , Max Guesses: {1}" 
            [toString model.guessesMade , toString model.maxGuesses ]
          else ""

      in 
        interpolate 
          " Your guess: {0}, State: {1}, Mystery Number: {2} {3}" 
          [ toString model.inputValue
          , toString model.gameState
          , toString model.mysteryNumber 
          , stateToString]

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
