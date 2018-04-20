{-|
Module      : Plotter
Description : plotting pixels
Copyright   : Just Nothing
Stability   : in progress
-}

module Plotter (initField, updateField, linearFieldIndex) where
import Types
import qualified Gradient                      (colorMap)
import qualified Data.Vector.Unboxed as Vector (unsafeThaw, unsafeFreeze,generate)
import qualified Data.Vector.Unboxed.Mutable as Mutable (modify)
import           Control.Monad.ST              (runST)


-- | Initialize field
initField :: Model -> Field
initField m = Vector.generate (sizeX*sizeY) initFunction
  where
    sizeX = mWidth m
    sizeY = mHeight m
    initFunction = mBackgroundColour m  

-- | Функция размещения в поле ряда точек.
-- Если я успею, то сделаю всё более красиво и понятно.
updateField  ::  Model
  -> [(Vec,Double,Transform)]
  -> Field
  -> Field
updateField model listCast field = let
    listFieldPoints = produceListFromCasts model $ filter (inBounds model) listCast
  in runST $ do 
     mutableVector <- Vector.unsafeThaw field
     _             <- mapM_
                        (plot mutableVector)
                        listFieldPoints
     updatedField  <- Vector.unsafeFreeze mutableVector
     return updatedField
  where
    plot vector = \(c,v) -> Mutable.modify vector c v

inBounds :: Model -> (Vec,Double,Transform) -> Bool
inBounds m ((x,y) , _ , _) = flag
  where
  	divHW = fromIntegral (mHeight m) / fromIntegral (mWidth m)
  	flag = abs x < 1 && abs y < divHW


-- | Генерация из списка Cast списка вида (mutate colour, position)
-- для работы 'Vector.Mutable.modify'
produceListFromCasts
  :: Model                -- ^ Параметры преобразований. Зачем я их таскаю?
  -> [(Vec,Double,Transform)]   -- ^ Структура бросков. TODO effective
  -> [(Cell -> Cell,Int)] -- ^ Результат - функция-модификатор и индекс.
produceListFromCasts model startList =
  map convert startList
  where
    convert (coord,col,ind) = (
        (calcColour ind)
      $ grad model
      $ col        
      ,   (linearFieldIndex model) .
          (pointBUStoFieldPoint model)
      $ coord             )
    grad = Gradient.colorMap . mGradient

-- | convert index from virtual field as BUS to real field as Vector
pointBUStoFieldPoint
  :: Model            -- параметры модели
  -> (Double, Double) -- точка из би-квадрата
  -> (Int,Int)        -- точка на поле
pointBUStoFieldPoint m (x, y) =
  ( truncate $ scale *( x+1)
  , truncate $ scale *(-y+divHW)
  )
  where
    divHW = fromIntegral (mHeight m) / fromIntegral (mWidth m)
    scale = fromIntegral (mWidth  m) / 2

-- | TODO alpha blending colours
calcColour :: Transform -> (Double,Double,Double) -> Cell -> Cell
calcColour _ (r1,g1,b1) (r2, g2, b2, a) = ( (r2+r1), (g2+g1), (b2+b1), (a+1))