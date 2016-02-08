module Game where

import Effects exposing (Effects, Never)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import String
--  import RandomNumber exposing (..)

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
   , Effects.none
  )

{--
randomNumber =
  RandomNumber.integerRange 
--}

-- UPDATE

type Action
  = Guess 
  | Restart
  | EnterText String


update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
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

          -- Update the guessesMade

          | guessesMade = model.guessesMade + 1

          -- Check the state of the game

          , gameState = checkGameState model
        }
        , Effects.none
      )

    -- Capture the input value from the text field in the model. This `EnterText`
    -- action is invoked each time the field value changes

    EnterText inputValue ->
      ( { model | inputValue =
            String.toInt inputValue 
              |> Result.toMaybe 
              |> Maybe.withDefault 0 
        }
        , Effects.none
      )

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




