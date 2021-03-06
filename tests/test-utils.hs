import System.Exit (exitFailure)
import Data.List (elemIndices, sort, nub, delete)

import Test.LeanCheck
import Test.LeanCheck.Invariants
import Test.LeanCheck.Operators
import Test.LeanCheck.TypeBinding
import Test.LeanCheck.Types (Nat)


main :: IO ()
main =
  case elemIndices False tests of
    [] -> putStrLn "Tests passed!"
    is -> do putStrLn ("Failed tests:" ++ show is)
             exitFailure

tests =
  [ True

  , checkNoDup 12
  , checkAscending 18
  , checkStrictlyAscending 20
  , checkLengthListingsOfLength 5 5
  , checkSizesListingsOfLength 5 5

  , productMaybeWith ($) [[const Nothing, Just]] [[1],[2],[3],[4]] == [[1],[2],[3],[4]]
  , productMaybeWith (flip ($))
                     [[1],[2],[3],[4]]
                     [[const Nothing],[Just]] == [[],[1],[2],[3],[4]]

  , holds 100 $ deleteT_is_map_delete 10 -:> nat
  , holds 100 $ deleteT_is_map_delete 10 -:> int
  , holds 100 $ deleteT_is_map_delete 10 -:> bool
  , holds 100 $ deleteT_is_map_delete 10 -:> int2
  ]

deleteT_is_map_delete :: (Eq a, Listable a) => Int -> a -> Bool
deleteT_is_map_delete n x = deleteT x tiers
                    =| n |= normalizeT (map (delete x) tiers)

checkNoDup :: Int -> Bool
checkNoDup n = noDupListsOf (tiers :: [[Int]])
       =| n |= tiers `suchThat` noDup
  where noDup xs = nub (sort xs) == sort xs

checkAscending :: Int -> Bool
checkAscending n = ascendingListsOf (tiers :: [[Nat]])
           =| n |= tiers `suchThat` ordered

checkStrictlyAscending :: Int -> Bool
checkStrictlyAscending n = setsOf (tiers :: [[Nat]])
                   =| n |= tiers `suchThat` strictlyOrdered

checkLengthListingsOfLength :: Int -> Int -> Bool
checkLengthListingsOfLength n m = all check [1..m]
  where check m = all (\xs -> length xs == m)
                $ concat . take n
                $ listsOfLength m natTiers

checkSizesListingsOfLength :: Int -> Int -> Bool
checkSizesListingsOfLength n m = all check [1..m]
  where check m = orderedBy compare
                $ map sum . concat . take n
                $ listsOfLength m natTiers

natTiers :: [[Nat]]
natTiers = tiers
