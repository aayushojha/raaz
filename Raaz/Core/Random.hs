{-# LANGUAGE TypeFamilies      #-}
{-# LANGUAGE KindSignatures    #-}
{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE DefaultSignatures #-}
{-# LANGUAGE CPP               #-}
module Raaz.Core.Random
  ( PRG(..), Random(..)

#ifdef HAVE_SYSTEM_PRG
  , SystemPRG
#endif

  ) where

import Control.Applicative
import Control.Monad   (void)
import Data.Word
import Foreign.Ptr     (castPtr)
import Foreign.Storable(Storable, peek)


import System.IO ( openBinaryFile, Handle, IOMode(ReadMode)
                 , BufferMode(NoBuffering), hSetBuffering
                 )


import Prelude

import Raaz.Core.ByteSource(InfiniteSource, slurpBytes)
import Raaz.Core.Types

-- | The class that captures pseudo-random generators. Essentially the
-- a pseudo-random generator (PRG) is a byte sources that can be
-- seeded.
class InfiniteSource prg => PRG prg where

  -- | Associated type that captures the seed for the PRG.
  type Seed prg :: *

  -- | Creates a new pseudo-random generators
  newPRG :: Seed prg -> IO prg

  -- | Re-seeding the prg.
  reseed :: Seed prg -> prg -> IO ()

-- | Stuff that can be generated by a pseudo-random generator.
class Random r where
  random :: PRG prg => prg -> IO r

  default random :: (PRG prg, Storable r) => prg -> IO r
  random = go undefined
    where go       :: (PRG prg, Storable a) => a -> prg -> IO a
          go w prg = let sz = byteSize w in
            allocaBuffer sz $ \ ptr -> do
              void $ slurpBytes sz prg ptr
              peek $ castPtr ptr

instance Random Word
instance Random Word16
instance Random Word32
instance Random Word64

instance Random w => Random (LE w) where
  random = fmap littleEndian . random

instance Random w => Random (BE w) where
  random = fmap bigEndian . random

instance (Random a, Random b) => Random (a,b) where
  random prg = (,) <$> random prg <*> random prg

instance (Random a, Random b, Random c) => Random (a,b,c) where
  random prg = (,,) <$> random prg <*> random prg <*> random prg

#ifdef HAVE_SYSTEM_PRG
-- | The system wide pseudo-random generator. The source is expected
-- to be of high quality, albeit a bit slow due to system call
-- overheads. It is expected that this source is automatically seeded
-- from the entropy pool maintained by the platform. Hence, it is
-- neither necessary nor possible to seed this generator which
-- reflected by the fact that the associated type @`Seed` `SystemPRG`@
-- is the unit type @()@.
#endif


-- Currently only POSIX platforms are supported where the file
-- @\/dev\/urandom@ acts as the underlying randomness source.
--
-- TODO: Support other platforms.
--
#ifdef HAVE_DEV_URANDOM
newtype SystemPRG = SystemPRG Handle


instance InfiniteSource SystemPRG where
  slurpBytes sz sprg@(SystemPRG hand) cptr = hFillBuf hand cptr sz >> return sprg


instance PRG SystemPRG where
  type Seed SystemPRG = ()

  newPRG _ = do h <- openBinaryFile "/dev/urandom" ReadMode
                hSetBuffering h NoBuffering
                return $ SystemPRG h
  reseed _ _ = return ()

#endif
