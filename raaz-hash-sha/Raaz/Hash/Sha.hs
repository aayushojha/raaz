{-# LANGUAGE DeriveDataTypeable         #-}
module Raaz.Hash.Sha
       ( SHA1(..)
       ) where

import Control.Applicative ((<$>), (<*>))
import Data.Bits(xor, (.|.))
import qualified Data.ByteString as B
import Data.Typeable(Typeable)
import Data.Word
import Foreign.Storable(Storable(..))
import Test.QuickCheck(Arbitrary(..))

import Raaz.Primitives
import Raaz.Hash
import Raaz.Util.Ptr(loadFromIndex, storeAtIndex)
import Raaz.Types

-- | The SHA1 hash value.
data SHA1 = SHA1 {-# UNPACK #-} !Word32BE
                 {-# UNPACK #-} !Word32BE
                 {-# UNPACK #-} !Word32BE
                 {-# UNPACK #-} !Word32BE
                 {-# UNPACK #-} !Word32BE deriving (Show, Typeable)

-- | Timing independent equality testing.
instance Eq SHA1 where
  (==) (SHA1 g0 g1 g2 g3 g4) (SHA1 h0 h1 h2 h3 h4) =   xor g0 h0
                                                   .|. xor g1 h1
                                                   .|. xor g2 h2
                                                   .|. xor g3 h3
                                                   .|. xor g4 h4
                                                   == 0


instance Storable SHA1 where
  sizeOf    _ = 5 * sizeOf (undefined :: Word32BE)
  alignment _ = alignment  (undefined :: Word32BE)
  peekByteOff ptr pos = SHA1 <$> peekByteOff ptr pos0
                             <*> peekByteOff ptr pos1
                             <*> peekByteOff ptr pos2
                             <*> peekByteOff ptr pos3
                             <*> peekByteOff ptr pos4
    where pos0   = pos
          pos1   = pos0 + offset
          pos2   = pos1 + offset
          pos3   = pos2 + offset
          pos4   = pos3 + offset
          offset = sizeOf (undefined:: Word32BE)

  pokeByteOff ptr pos (SHA1 h0 h1 h2 h3 h4) =  pokeByteOff ptr pos0 h0
                                            >> pokeByteOff ptr pos1 h1
                                            >> pokeByteOff ptr pos2 h2
                                            >> pokeByteOff ptr pos3 h3
                                            >> pokeByteOff ptr pos4 h4
    where pos0   = pos
          pos1   = pos0 + offset
          pos2   = pos1 + offset
          pos3   = pos2 + offset
          pos4   = pos3 + offset
          offset = sizeOf (undefined:: Word32BE)

instance CryptoStore SHA1 where
  load cptr = SHA1 <$> load cptr
                   <*> loadFromIndex cptr 1
                   <*> loadFromIndex cptr 2
                   <*> loadFromIndex cptr 3
                   <*> loadFromIndex cptr 4

  store cptr (SHA1 h0 h1 h2 h3 h4) =  store cptr h0
                                   >> storeAtIndex cptr 1 h1
                                   >> storeAtIndex cptr 2 h2
                                   >> storeAtIndex cptr 3 h3
                                   >> storeAtIndex cptr 4 h4

instance Arbitrary SHA1 where
  arbitrary = SHA1 <$> arbitrary   -- h0
                   <*> arbitrary   -- h1
                   <*> arbitrary   -- h2
                   <*> arbitrary   -- h3
                   <*> arbitrary   -- h4

instance BlockPrimitive SHA1 where
  blockSize _ = cryptoCoerce $ BITS (512 :: Int)
  {-# INLINE blockSize #-}


instance Hash SHA1 where
  maxAdditionalBlocks _ = 1

  padLength = padLength64
  padding   = padding64


firstPadByte :: Word8
firstPadByte = 127

-- | Number of bytes in the padding for the first pad byte and the
-- length encoding for a 64-bit length appended hash like SHA1
extra64  :: BYTES Int
extra64  = BYTES $ 1 + sizeOf (undefined :: Word64)

-- | Padding length for a 64-bit length appended hash like SHA1.
padLength64 :: Hash h => h -> BITS Word64 -> BYTES Int
{-# INLINE padLength64 #-}
padLength64 h l | r >= extra64 = r
                | otherwise    = r + blockSize h
  where lb :: BYTES Int
        lb    = cryptoCoerce l `rem` blockSize h
        r     = blockSize h - lb

-- | Padding string for a 64-bit length appended hash like SHA1.
padding64 :: Hash h => h -> BITS Word64 -> B.ByteString
padding64 h l = B.concat [ B.singleton firstPadByte
                         , B.replicate zeros 0
                         , toByteString lBits
                         ]
     where r      = padLength h l :: BYTES Int
           zeros  = fromIntegral $ r - extra64
           lBits  = cryptoCoerce l :: BITS Word64BE
