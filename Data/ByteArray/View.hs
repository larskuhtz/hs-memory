-- |
-- Module      : Data.ByteArray.View
-- License     : BSD-style
-- Maintainer  : Nicolas DI PRIMA <nicolas@di-prima.fr>
-- Stability   : stable
-- Portability : Good
--
-- a View on a given ByteArrayAccess
--

module Data.ByteArray.View
    ( View
    , view
    , takeView
    , dropView
    ) where

import Data.ByteArray.Methods
import Data.ByteArray.Types
import Data.Memory.PtrMethods
import Data.Memory.Internal.Compat
import Foreign.Ptr (plusPtr)

import Prelude hiding (length, take, drop)

-- | a view on a given bytes
data View bytes = View
    { viewOffset :: !Int
    , viewSize   :: !Int
    , unView     :: !bytes
    }

instance ByteArrayAccess bytes => Eq (View bytes) where
    (==) = constEq

instance ByteArrayAccess bytes => Ord (View bytes) where
    compare v1 v2 = unsafeDoIO $
        withByteArray v1 $ \ptr1 ->
        withByteArray v2 $ \ptr2 ->
            memCompare ptr1 ptr2 (max (viewSize v1) (viewSize v2))

instance ByteArrayAccess bytes => Show (View bytes) where
    showsPrec p v r = showsPrec p (viewUnpackChars v []) r

instance ByteArrayAccess bytes => ByteArrayAccess (View bytes) where
    length = viewSize
    withByteArray v f = withByteArray (unView v) $ \ptr -> f (ptr `plusPtr` (viewOffset v))

viewUnpackChars :: ByteArrayAccess bytes
                => View bytes
                -> String
                -> String
viewUnpackChars v xs = chunkLoop 0
  where
    len = length v

    chunkLoop :: Int -> [Char]
    chunkLoop idx
        | len == idx = []
        | (len - idx) > 63 =
            bytesLoop idx (idx + 64) (chunkLoop (idx + 64))
        | otherwise =
            bytesLoop idx (len - idx) xs

    bytesLoop :: Int -> Int -> [Char] -> [Char]
    bytesLoop idx chunkLenM1 paramAcc =
        loop (idx + chunkLenM1 - 1) paramAcc
      where
        loop i acc
            | i == idx  = (rChar idx : acc)
            | otherwise = loop (i - 1) (rChar idx : acc)

    rChar :: Int -> Char
    rChar idx = toEnum $ fromIntegral $ index v idx

-- | create a view on a given bytearray
view :: ByteArrayAccess bytes
     => bytes -- ^ the byte array we put a view on
     -> Int   -- ^ the offset to start the byte array on
     -> Int   -- ^ the size of the view
     -> View bytes
view b offset size = View offset size b

-- | create a view from the given bytearray
takeView :: ByteArrayAccess bytes
         => bytes -- ^ byte aray
         -> Int   -- ^ size of the view
         -> View bytes
takeView b size = View 0 sz b
  where
    sz :: Int
    sz = min (length b) size

-- | create a view from the given byte array
-- starting after having dropped the fist n bytes
dropView :: ByteArrayAccess bytes
         => bytes -- ^ byte array
         -> Int   -- ^ the number of bytes do dropped before creating the view
         -> View bytes
dropView b offset = View offset' (length b - offset') b
  where
    offset' :: Int
    offset' = min (length b) offset

