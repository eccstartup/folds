{-# LANGUAGE Trustworthy #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE Rank2Types #-}
{-# LANGUAGE ExistentialQuantification #-}
module Data.Fold.R'
  ( R'(..)
  ) where

import Control.Applicative
import Control.Comonad
import Control.Lens
import Data.Foldable hiding (sum, product)
import Data.Fold.Class
import Data.Functor.Extend
import Data.Functor.Apply
import Data.Profunctor.Unsafe
import Unsafe.Coerce
import Prelude hiding (foldr, sum, product, length)

-- strict right folds
data R' b a = forall r. R' (r -> a) (b -> r -> r) r

instance Folding R' where
  enfold t (R' k h z)     = k (foldr' h z t)
  enfoldOf l s (R' k h z) = k (foldrOf' l h z s)

instance Profunctor R' where
  dimap f g (R' k h z) = R' (g.k) (h.f) z
  {-# INLINE dimap #-}
  rmap g (R' k h z) = R' (g.k) h z
  {-# INLINE rmap #-}
  lmap f (R' k h z) = R' k (h.f) z
  {-# INLINE lmap #-}
  (#.) _ = unsafeCoerce
  {-# INLINE (#.) #-}
  x .# _ = unsafeCoerce x
  {-# INLINE (.#) #-}

instance Choice R' where
  left' (R' k h z) = R' (_Left %~ k) step (Left z) where
    step (Left x) (Left y) = Left (h x y)
    step (Right c) _ = Right c
    step _ (Right c) = Right c
  {-# INLINE left' #-}

  right' (R' k h z) = R' (_Right %~ k) step (Right z) where
    step (Right x) (Right y) = Right (h x y)
    step (Left c) _ = Left c
    step _ (Left c) = Left c
  {-# INLINE right' #-}

instance Functor (R' a) where
  fmap f (R' k h z) = R' (f.k) h z
  {-# INLINE fmap #-}

  (<$) b = \_ -> pure b
  {-# INLINE (<$) #-}

instance Comonad (R' b) where
  extract (R' k _ z) = k z
  {-# INLINE extract #-}

  duplicate (R' k h z) = R' (R' k h) h z
  {-# INLINE duplicate #-}

  extend f (R' k h z)  = R' (f . R' k h) h z
  {-# INLINE extend #-}

data Pair a b = Pair !a !b

instance Applicative (R' b) where
  pure b = R' (\() -> b) (\_ () -> ()) ()
  {-# INLINE pure #-}

  R' xf bxx xz <*> R' ya byy yz = R'
    (\(Pair x y) -> xf x $ ya y)
    (\b (Pair x y) -> Pair (bxx b x) (byy b y))
    (Pair xz yz)
  {-# INLINE (<*>) #-}

  (<*) m = \_ -> m
  {-# INLINE (<*) #-}

  _ *> m = m
  {-# INLINE (*>) #-}

instance Extend (R' b) where
  extended = extend
  {-# INLINE extended #-}

  duplicated = duplicate
  {-# INLINE duplicated #-}

instance Apply (R' b) where
  (<.>) = (<*>)
  {-# INLINE (<.>) #-}

  (<.) m = \_ -> m
  {-# INLINE (<.) #-}

  _ .> m = m
  {-# INLINE (.>) #-}

instance ComonadApply (R' b) where
  (<@>) = (<*>)
  {-# INLINE (<@>) #-}

  (<@) m = \_ -> m
  {-# INLINE (<@) #-}

  _ @> m = m
  {-# INLINE (@>) #-}
