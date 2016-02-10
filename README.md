Number Guessing Game in Elm - With Random Numbers
===========================

This is the 2nd version of the [Number Guessing Game](https://github.com/kittykatattack/numberGuessingGame) which uses
random numbers to generate the mystery number. (Make sure you check
out [how that first version works before you tackle this one](https://github.com/kittykatattack/numberGuessingGame)).
This new version of the game will give you a good overview of how to
generate and use random numbers in a typical Elm application. You can
play a demo of the game here:

https://gitcdn.xyz/repo/kittykatattack/randomNumberGame/master/index.html

A huge thanks to [Petre Damoc](https://gist.github.com/pdamoc) who
contributed all this new code and explained to me how it works. You
can read his original code [here](https://gist.github.com/pdamoc/3c4a4c9564d6235f504c), 
and the Reddit discussion about it [here](https://www.reddit.com/r/elm/comments/44skl5/request_for_feedback_number_guessing_game/).

Here are the important new additions to the game:

Generating a random number between 1 and 100
--------------------------------------------

First, there's a new Signal called `newRandIntSignal` that's added 
as an `input` to the app in the `Main.elm` file.
```elm
app =
  StartApp.start
   { init = init
   , update = update
   , view = view
   , inputs = [Game.newRandIntSignal]
   }
```
In the `Game.elm` file, a new function called `newRandIntSignal` converts `Time.timestamp` into an `Action`.
```js
newRandIntMB = Signal.mailbox ()

newRandIntSignal = 
  newRandIntMB.signal
  |> Time.timestamp 
  |> Signal.map toAction
```
This is required because the `timestamp` is needed to generate a 
**seed** for the random number generator. 

Next, the `timestamp` is converted 
into a random integer between 1 and 100, and a new action called `NewMysteryInt` runs.
```elm
toAction (t, _) = 
  let 
    (newInt, _) = generate (int 1 100) (initialSeed (truncate t))
  in 
    NewMystery newInt
```
The `NewMystery` action in the `update` function supplies the new random 
integer, `newInt`, and uses it to update the model's `mysteryNumber`.
```elm
NewMystery newInt -> 
  noFx { model | mysteryNumber = newInt}
```
The `noFx` function is just a handy way to help de-clutter boilerplate code 
if you want to return a model but don't need to run any effects.
```elm
noFx model = (model, Effects.none)
```
The first random number is generated when the model is initialized, 
by calling the `newIntEffect` Effect.
```elm
init : (Model, Effects Action)
init =
  ({ mysteryNumber = 50
  , maxGuesses = 10
  , guessesMade = 0
  , gameState = Started
  , inputValue = 0
  }, newIntEffect)

newIntEffect = 
  Signal.send newRandIntMB.address ()
  |> Task.map (always (EnterText ""))
  |> Effects.task
```
It can be a little tricky to understand how `newIntEffect` works.
Here's a description of how this works from the Reddit
thread: 

> The `newIntEffect` is basically a task that will be run eventually by the runtime. 
> It does not actually do anything in the code, it is only defined or described. 
> As I said, this is tricky, especially if the primary experience is with an imperative 
> language where you call things one after the other. In Elm you just declare things. 
> You can play with the app and see it stop working once you comment out the port tasks 
> lines. Those two lines are essential for the routing of the Tasks to the runtime.
> Only there do they have a chance to be executed.

Why does this do: `Task.map (always (EnterText ""))`?

> The task produced by `Signal.send` needs to get to the runtime and be executed. 
> With current Effects library, this means that the result of the task needs 
> to be of type `Action`. After the task is executed in the runtime, this resulting 
> action is sent back into the program BUT in the context of the send we are not 
> interested in the result of that task. So, the main pattern I've seen so far is 
> to just add an `NoOpaction` for such cases BUT, in your case, I just re-purposed 
> `EnterText`. It doesn't really matter if `EnterText` arrives before or after 
> `NewMystery`, the state of the model would be the same.

Additional improvements
-----------------------

This new version of the game also includes some additional, more
cosmetic, improvements to the code.

###Making a conditional statement more readable

In the first version of the Number Guessing Game, the `checkGameState`
function looked like this:
```elm
checkGameState model =
  if model.guessesMade >= model.maxGuesses && model.inputValue /= model.mysteryNumber
     then
       Lost

  else if model.guessesMade <= model.maxGuesses && model.inputValue == model.mysteryNumber 
      then
        Won

  else InProgress
```
It works, but it's a bit verbose and difficult to read. By using
pattern matching with a tuple, you can use this much more concise
code:
```elm
checkGameState model =
  case 
    ( model.guessesMade >= model.maxGuesses
    , model.inputValue == model.mysteryNumber
    ) 
  of
    (True, _) -> Lost
    (_, True) -> Won
     _ -> InProgress
```
Just follow this same format if you have additional cases.

###Using the String.Interpolate package

This new code also uses the [String.Interpolate package](http://package.elm-lang.org/packages/lukewestby/elm-string-interpolate/1.0.0/) to help make
complex string concatenation much more readable. Here's how it's used
in the `stateMessage` function in the view.
```elm
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
```
And that's it!



