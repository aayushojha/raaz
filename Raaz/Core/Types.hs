-- | This module exposes some core types used through out the Raaz
-- library. One of the major goals of the raaz cryptographic library
-- use the type safety of Haskell to catch some common bugs at compile
-- time. As of now we address three kinds of errors
--

module Raaz.Core.Types
       ( module Raaz.Core.Types.Equality
       , module Raaz.Core.Types.Endian
       , module Raaz.Core.Types.Pointer
       , module Raaz.Core.Types.Tuple
       , module Raaz.Core.Types.Copying
     --  , Src, Dest, source, destination
       , Describable(..)
       ) where


import Raaz.Core.Types.Describe
import Raaz.Core.Types.Equality
import Raaz.Core.Types.Endian
import Raaz.Core.Types.Pointer
import Raaz.Core.Types.Tuple
import Raaz.Core.Types.Copying( Src, Dest, source, destination)

{-# ANN module "HLint: ignore Use import/export shortcut" #-}
