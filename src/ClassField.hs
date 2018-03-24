{-|
Module      : ClassField
Description : operations with field, generating invocation to Model
Copyright   : Just Nothing
Stability   : in progress
-}
module ClassField where

import Graphics.Gloss()
import System.Random
import Data.Matrix
import Types
import Const
import GVector()
-- | Обёртка над Field, играющая роль мира. Без грязного IO.
data World =
  World  {
    mugenga :: Field,  -- ^ 無限画
    getSGen :: StdGen, -- ^ standart pseudorandom number generator
    busList :: [Vec]  -- ^ BiUnitSquare coverage list
        }
-- | Точка и цвет в карте градиентов [0,1)
type Cast = (Vec, Double)
-- | Бросок с привязанным генератором
type CastGen = (GVec,Double)
-- | Поле есть матрица цветов
type Field = Matrix UnsafeColour
-- | Цвета без нормализации и проверки на нормировку
type UnsafeColour = (Float,Float,Float,Float)
-- | Создание изначального поля
-- размером икс на игрек
createField :: Int -> Int -> Field
createField x y = matrix x y (initFunction x y)
-- | Начальное заполнение фона
-- -> function from field point to unsafe colour
initFunction
  :: Int -- ^ width
  -> Int -- ^ heigth
  -> ((Int,Int)->UnsafeColour)
initFunction _ _ =
  ( \_ -> (0.13,0.54,0.13,1.0))
{-| ^ веселья ради можно поставить что-то ещё,
 но цвет лесной зелени приятен глазу, как ветви молодых деревьев в летнем саду.
-}

-- | обновление поля - добавление в него серий бросков, числом от дельты времени
updateWorld
  :: Float -- ^ delta time
  -> World -- ^ Old World
  -> World -- ^ New World
updateWorld dt bnw = 
  generator
  bnw
  numCast --(floor (dt*numCast))

-- | генератор нового поля
-- генерируется новая серия бросков одной точки из bus
-- в каждой итерации, по счётчику с декрементом
generator
  :: World -- ^ BNW
  -> Int   -- ^ iterator for loop
  -> World
generator bnw n | n>0 = rty (iter (mugenga bnw, busPoint bnw) 0) (n-1)
  where
    rty (f,(gvec,_)) = generator $!(World f (gvGen gvec) $ tail . busList $ bnw)
generator a _  = a

-- | BiUnitSquarePoint  from [-1,1)^2
-- with colour 0.5
busPoint :: World -> CastGen
busPoint bnw = (GVec (getSGen bnw) (head $ busList bnw), 0.5)

-- | Iterator for loop inner_iter
-- new Field, new PRNG
-- броски одной точки
-- итерации по счётчику с инкрементом
-- начало отрисовки с нижнего порога
-- конец отрисовки на верхнем пороге
-- pack - упаковка результата с отисовкой в поле
iter
  :: (Field, CastGen) -- ^ old field
  -> Int              -- ^ counter
  -> (Field, CastGen) -- ^ new field
iter (f, cgen) n
  | n<lowThreshold = iter (f,(newCast cgen)) (n+1)
  | n<innerIter = iter (pack (newCast cgen)) (n+1)
  | otherwise = (f, cgen)
  where
    pack newC@(gvec, colour) = ((plot (gvVec gvec, colour) f), newC)

-- | TODO Генерация новой точки
newCast :: CastGen -> CastGen
newCast (gvector, colour) =
  let
    (choice,generator) = random $ gvGen gvector
    transform = askTransform mainModel choice
  in applyTransform transform colour (GVec generator (gvVec gvector))

-- | Размещение точки в поле
plot
  :: Cast  -- ^ cast: (point, gradient)
  -> Field -- ^ old field
  -> Field -- ^ new field
plot (ccc@(x, y), colC) field
  | flag = setElem colour coord field
  | otherwise =
    error ("Field"++(show coord)++(show ccc)++(show(halfX,halfY)))
    -- field
  where
    colour = merge colC $ getPoint coord
    getPoint (a,b) = getElem a b field
    flag = control (x', y')
-- Orthogonal transformation (x,y)
    x' = ((y*sinTheta + x*cosTheta) - shiftX) *scaleFactor
    y' = ((y*cosTheta - x*sinTheta) - shiftY) *scaleFactor
-- Translation on shift vector in discrete field and scaling
    ordX = x' + halfX + 1
    ordY = y' + halfY + 1
    coord = (trr ordX, trr ordY)
    trr = truncate
-- | проверка границ поля
control :: (Double,Double) -> Bool
control (a,b) = not (cond halfX a || cond halfY b)
  where
    cond size x =
      isNaN x ||
      isInfinite x ||
      x < - size ||
      x >   size
-- | TODO alpha blending colours
merge :: Double -> UnsafeColour -> UnsafeColour
merge _ col = mix (1,1,1) col -- asking gradient
  where
    mix (r,g,b) (t,h,n,s) = (1,0,0,1)--(r+t,g+h,b+n,s+1)

-- | Выбор трансформы из списка
-- нашей модели
askTransform
  :: Model -- ^ модель
  -> Double-- ^ случайная величина [0,1)
  -> Transform
askTransform model choice =
  let
    thres = choice * (sumweight model)
    list = transforms model
  in findTrans (thres - (weight $ head list)) list
-- | перебор по списку до первого не превосходящего порог
findTrans :: Double -> [Transform] -> Transform
findTrans thres (x:y:xs)
  | (thres <= 0) = x
  | otherwise = findTrans (thres - (weight y)) (y:xs)
findTrans _ x = head x
-- | Применение трансформы
-- к цвету и вектору
applyTransform
  :: Transform
  -> Double   -- ^ цвет в карте градиентов
  -> GVec     -- ^ вектор
  -> (GVec, Double)
applyTransform transform colour gvec =
  let
    colSpeed = colorSpeed    transform
    colPosit = colorPosition transform
    newColour = (colour*abs(1+colSpeed) + colPosit*abs(1-colSpeed))/2
    variatTr = variation transform
    varFuncT = (function variatTr) $ (params variatTr)
  in (varFuncT gvec,newColour)