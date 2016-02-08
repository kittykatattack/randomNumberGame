module RandomNumber where

import Random exposing (int, initialSeed, generate) 
import Time exposing (Time) 

import Effects exposing (Effects, Never)
import Signal exposing (Signal) 



type alias Model = { seed : Random.Seed, value : Int }

init : (Model, Effects Action) 
init = ({ seed = initialSeed 42, value = 0 }, Effects.tick FirstSeed) 

randInt = int 1 100

integerRange =
  let
    newRandomModel = fst (update NewRandom (fst init))
  in
    newRandomModel.value   

type Action = NewRandom | FirstSeed Time

update : Action -> Model -> (Model, Effects Action) 
update action model = 
  case action of 
    FirstSeed time -> 
      let 
        (value', seed') = generate randInt (initialSeed (truncate time))
      in 
        ({model| value=value', seed = seed' }, Effects.none)

    NewRandom -> 
      let 
        (value', seed') = generate randInt model.seed
      in 
        ({model | value = value', seed = seed'}, Effects.none)



