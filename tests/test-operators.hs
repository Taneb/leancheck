import System.Exit (exitFailure)
import Data.List (elemIndices,sort)
import Test.LeanCheck
import Test.LeanCheck.Operators
import Test.LeanCheck.TypeBinding


main :: IO ()
main =
  case elemIndices False (tests 100) of
    [] -> putStrLn "Tests passed!"
    is -> do putStrLn ("Failed tests:" ++ show is)
             exitFailure

tests :: Int -> [Bool]
tests n =
  [ True

  , holds n $ (not . not) === id
  , fails n $ abs === (* (-1))             -:> int
  , holds n $ (+) ==== (\x y -> sum [x,y]) -:> int
  , fails n $ (+) ==== (*)                 -:> int

  , holds n $ const True  &&& const True  -:> bool
  , fails n $ const False &&& const True  -:> int
  , holds n $ const False ||| const True  -:> int
  , fails n $ const False ||| const False -:> int

  , holds n $ commutative (+)  -:> int
  , holds n $ commutative (*)  -:> int
  , holds n $ commutative (++) -:> [()]
  , holds n $ commutative (&&)
  , holds n $ commutative (||)
  , fails n $ commutative (-)  -:> int
  , fails n $ commutative (++) -:> [bool]
  , fails n $ commutative (==>)

  , holds n $ associative (+)  -:> int
  , holds n $ associative (*)  -:> int
  , holds n $ associative (++) -:> [int]
  , holds n $ associative (&&)
  , holds n $ associative (||)
  , fails n $ associative (-)  -:> int
  , fails n $ associative (==>)

  , holds n $ distributive (*) (+) -:> int
  , fails n $ distributive (+) (*) -:> int

  , holds n $ transitive (==) -:> bool
  , holds n $ transitive (<)  -:> bool
  , holds n $ transitive (<=) -:> bool
  , fails n $ transitive (/=) -:> bool
  , holds n $ transitive (==) -:> int
  , holds n $ transitive (<)  -:> int
  , holds n $ transitive (<=) -:> int
  , fails n $ transitive (/=) -:> int

  , holds n $ idempotent id   -:> int
  , holds n $ idempotent abs  -:> int
  , holds n $ idempotent sort -:> [bool]
  , fails n $ idempotent not

  , holds n $ identity id   -:> int
  , holds n $ identity (+0) -:> int
  , holds n $ identity sort -:> [()]
  , holds n $ identity (not . not)
  , fails n $ identity not

  , holds n $ notIdentity not
  , fails n $ notIdentity abs    -:> int
  , fails n $ notIdentity negate -:> int
  ]
