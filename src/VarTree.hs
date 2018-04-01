{-|
Module      : VarTree
Description : operations with Expression Tree of Variations
Copyright   : Just Nothing
Stability   : in progress
-}
module VarTree where
import Prelude  
--import System.Random
import Types

-- | проверка, не выходит ли индекс за границу списка
inRange :: [a]->Int->Bool
inRange l i
         | i < 0 = False
         | i >=length l = False
         | otherwise = True

-- | получает два вектора, возвращает вектор
type Operation = GVec->GVec->GVec
-- | путь точки
type Path = [Int]

-- | Дерево выражения над вариациями
-- | Позволяет задать произвольное выражение из вариаций,
-- | и при этом иметь доступ к любым их параметрам и структуре выражения
-- | что необходимо для работы скриптов и изменения модели через гуи
data VTree = Node Operation [VTree] | Leaf Variation

-- | вставка элемента
insertAt :: Int->a->[a]->[a]
insertAt z y xs = as ++ (y:bs)
                  where (as,bs) = splitAt z xs

-- | получить поддерево по заданной последовательности переходов по вершинам
getSubTree :: VTree -> Path -> Maybe VTree
getSubTree vt [] = Just vt
getSubTree (Node _ l) (x:xs) | inRange l x =  getSubTree (l !! x) xs
                             | otherwise = Nothing
getSubTree (Leaf _) _ = Nothing

-- | проверка на правильность дерева
isValidTree :: VTree -> Bool
isValidTree (Node _ []) = False
isValidTree  (Leaf _) = True
isValidTree (Node _ list) = and (map isValidTree list) 

--removeSubTree :: VTree -> Path -> VTree -- откуда \ по какому адресу удалять
--replaceSubTree :: VTree->Path->VTree->VTree -- откуда \ по какому адресу \ чем заменить 

{-
insertSubTree :: Path->VTree->VTree->VTree
insertSubTree _ _ (Leaf v) = Leaf v
insertSubTree _ subT (Node op []) = Node op [subT]
insertSubTree [x] subt (Node op l) = Node op (insertAt x subt l)
insertSubTree (x:xs) subt (Node op l) | x < 0 = Node op (insertAt 0 (insertSubTree xs subt (l !! 0)) l) 
                                      | x >= length l = insertSubTree xs subt (l !! (length l - 1))
                                      | otherwise = insertSubTree xs subt (l !! x)
                                      -}