
{-# OPTIONS_GHC -fno-warn-orphans #-}
{-# LANGUAGE OverloadedStrings    #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Raaz.Hash.Sha256Spec where

import           Prelude hiding (replicate)

import           Common
import qualified Common.Hash as CH

hashesTo :: ByteString -> SHA256 -> Spec
hashesTo = CH.hashesTo

hmacsTo  :: ByteString -> HMAC SHA256 -> Key (HMAC SHA256) -> Spec
hmacsTo  = CH.hmacsTo

spec :: Spec
spec =  do

  basicEndianSpecs (undefined :: SHA256)

  --
  -- Some unit tests
  --
  ""    `hashesTo` "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

  "abc" `hashesTo` "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"

  "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq" `hashesTo`
    "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1"

  "The quick brown fox jumps over the lazy dog" `hashesTo`
    "d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592"

  "The quick brown fox jumps over the lazy cog" `hashesTo`
    "e4c4d8f3bf76b692de791a173e05321150f7a345b46484fe427f6acc7ecc81be"

  "The quick brown fox jumps over the lazy dog The quick brown fox jumps over the lazy dog The quick brown fox jumps over the lazy dog The quick brown fox jumps over the lazy dog The quick brown fox jumps over the lazy dog" `hashesTo`
    "86c55ba51d6b4aef51f4ae956077a0f661d0b876c5774fef3172c4f56092cbbd"

  hmacSpec

hmacSpec :: Spec
hmacSpec = do
  with ("0b" `repeated` 20)  $ "Hi There" `hmacsTo` "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7"

  with ("aa" `repeated` 20)  $ (replicate (50 :: BYTES Int) 0xdd) `hmacsTo` "773ea91e36800e46854db8ebd09181a72959098b3ef8c122d9635514ced565fe"

  with ("aa" `repeated` 131) $ "Test Using Larger Than Block-Size Key - Hash Key First" `hmacsTo`
    "60e431591ee0b67f0d8a26aacbf5b77f8e0bc6213728c5140546040f0ee37f54"

  with ("aa" `repeated` 131) $ "This is a test using a larger than block-size key and a larger than block-size data. The key needs to be hashed before being used by the HMAC algorithm." `hmacsTo` "9b09ffa71b942fcb27635fbcd5b0e944bfdc63644f0713938a7f51535c3a35e2"

  let key = fromString $ (show  :: Base16 -> String) $ encodeByteString "Jefe"
      in with key  $ "what do ya want for nothing?" `hmacsTo` "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843"
