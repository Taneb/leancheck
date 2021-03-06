-- | A simple property-based testing library based on
--   enumeration of values via lists of lists.
--
-- This module re-exports Test.LeanCheck but some test functions have been
-- specialized to catch errors (see the explicit export list below).
--
-- This module is unsafe, it uses `unsafePerformIO` to catch errors.
{-# LANGUAGE CPP #-}
module Test.LeanCheck.Error
  ( holds
  , fails
  , exists
  , counterExample
  , counterExamples
  , witness
  , witnesses
  , results

  , errorToNothing
  , errorToFalse
  , errorToTrue
  , anyErrorToNothing

  , module Test.LeanCheck
  )
where

#if __GLASGOW_HASKELL__ <= 704
import Prelude hiding (catch)
#endif

import Test.LeanCheck hiding
  ( holds
  , fails
  , exists
  , counterExample
  , counterExamples
  , witness
  , witnesses
  , results
  )

import qualified Test.LeanCheck as C
  ( holds
  , fails
  , results
  )

import Control.Monad (liftM)
import System.IO.Unsafe (unsafePerformIO)
import Data.Maybe (listToMaybe)
import Control.Exception ( Exception
                         , SomeException
                         , ArithException
                         , ArrayException
                         , ErrorCall
                         , PatternMatchFail
                         , catch
                         , catches
                         , Handler (Handler)
                         , evaluate
                         )

-- | Takes a value and a function.  Ignores the value.  Binds the argument of
--   the function to the type of the value.
bindArgumentType :: a -> (a -> b) -> a -> b
bindArgumentType _ f = f

-- | Transforms a value into 'Just' that value or 'Nothing' on some errors:
--
--   * ArithException
--   * ArrayException
--   * ErrorCall
--   * PatternMatchFail
errorToNothing :: a -> Maybe a
errorToNothing x = unsafePerformIO $
  (Just `liftM` evaluate x) `catches` map ($ return Nothing)
                                      [ hf (undefined :: ArithException)
                                      , hf (undefined :: ArrayException)
                                      , hf (undefined :: ErrorCall)
                                      , hf (undefined :: PatternMatchFail)
                                      ]
  where hf :: Exception e => e -> IO a -> Handler a -- handlerFor
        hf e h = Handler $ bindArgumentType e (\_ -> h)

-- | Transforms a value into 'Just' that value or 'Nothing' on error.
anyErrorToNothing :: a -> Maybe a
anyErrorToNothing x = unsafePerformIO $
  (Just `liftM` evaluate x) `catch` \e -> do let _ = e :: SomeException
                                             return Nothing

errorToFalse :: Bool -> Bool
errorToFalse p = case errorToNothing p of
                   Just p' -> p
                   Nothing -> False

errorToTrue :: Bool -> Bool
errorToTrue p = case errorToNothing p of
                  Just p' -> p
                  Nothing -> True


holds,fails,exists :: Testable a => Int -> a -> Bool
holds n = errorToFalse . C.holds n
fails n = errorToTrue  . C.fails n
exists n = or . take n . map snd . results

counterExample,witness :: Testable a => Int -> a -> Maybe [String]
counterExample n = listToMaybe . counterExamples n
witness        n = listToMaybe . witnesses n

counterExamples,witnesses :: Testable a => Int -> a -> [[String]]
counterExamples n = map fst . filter (not . snd) . take n . results
witnesses       n = map fst . filter snd         . take n . results

results :: Testable a => a -> [([String],Bool)]
results = map (mapSnd errorToFalse) . C.results
  where mapSnd f (x,y) = (x,f y)
