import Data.Char (isDigit, digitToInt)
import Data.List (intersperse, transpose, (\\))

-------------
-- Data Types
-------------

type Sudoku = Grid Space

type Grid a = [Row a]

type Row a = [a]

type Space = Int

type Choices = [Space]

---------------
-- Grid Slicing
---------------

rows :: Grid a -> [Row a]
rows = id

cols :: Grid a -> [Row a]
cols = transpose

-- tpose :: [[a]] -> [[a]]
-- tpose [] = []
-- tpose [xs] = [[x] | x <- xs]
-- tpose (ys:yss) = zipWith (:) ys (tpose yss)

threes :: [a] -> [[a]]
threes [] = []
threes xs = ys : threes zs
    where
        (ys, zs) = splitAt 3 xs 

subGrids :: Grid a -> [Row a]
subGrids = concatMap chop3Rows . threes
    where
        chop3Rows = map concat . transpose . map threes

--------------------
-- Validity Checking
--------------------

singleton :: [a] -> Bool
singleton [_] = True
singleton _ = False

nodups :: Eq a => [a] -> Bool
nodups [] = True
nodups (x:xs) = not (elem x xs) && nodups xs

-- All spaces have only one possible choice
isComplete :: Grid Choices -> Bool
isComplete = all (all singleton)

-- Has any spaces with no possible choices
hasEmptyChoice :: Grid Choices -> Bool
hasEmptyChoice = any (any null)

validSolution :: Grid Space -> Bool
validSolution g = all nodups (rows g)
    && all nodups (cols g)
    && all nodups (subGrids g)

-- Contains no duplicate singletons along any row, column or sub-grid
isValid :: Grid Choices -> Bool
isValid g = all valid (rows g)
    && all valid (cols g)
    && all valid (subGrids g)
    where
        valid = nodups . concat . filter singleton

-- Either no choices or a conflicting singleton
isImpossible :: Grid Choices -> Bool
isImpossible g = hasEmptyChoice g || not (isValid g)

-----------------
-- Grid Expansion
-----------------

cartProd :: [[a]] -> [[a]]
cartProd [] = [[]]
cartProd (xs:xss) = [y:ys | y <- xs, ys <- cartProd xss]

-- Enumerates all possible grids from choices in given grid
enumGrids :: Grid Choices -> [Grid Space]
enumGrids = cartProd . map cartProd

expandOn :: (Choices -> Bool) -> Grid Choices -> [Grid Choices]
expandOn f g = [rs1 ++ (css1 ++ [c] : css2) : rs2 | c <- cs]
    where
        (css1, cs:css2) = break f r
        (rs1, r:rs2) = break (any f) g

expandShortest :: Grid Choices -> [Grid Choices]
expandShortest g = expandOn isShortest g
    where
        isShortest = (==) shortest . length
        shortest = minimum $ concatMap (map length) g

expandNonSingle :: Grid Choices -> [Grid Choices]
expandNonSingle = expandOn (not . singleton)

------------
-- Filtering
------------

singles :: [Choices] -> [Space]
singles = concat . filter singleton

-- Filter out all choices that already appear as singles in the given row
filterSingles :: [Choices] -> [Choices]
filterSingles xs = map removeSingles xs
    where
        removeSingles cs
            | singleton cs = cs
            | otherwise    = cs \\ singles xs

filterChoices :: Grid Choices -> Grid Choices
filterChoices = filterF rows . filterF cols . filterF subGrids
    where
        filterF f = f . map filterSingles . f

fix :: Eq a => (a -> a) -> a -> a
fix f x = if x == x' then x else fix f x'
    where x' = f x

----------
-- Solvers
----------

-- Filters valid solutions from the list of all possible grids
bruteForce :: Grid Choices -> [Grid Space]
bruteForce = filter validSolution . enumGrids

-- Repeatedly filters invalid choices until no more changes can be made
recursiveFilter :: Grid Choices -> [Grid Space]
recursiveFilter = filter validSolution . enumGrids . fix filterChoices

-- Similar to recursiveFilter except if the grid is still complete i.e.
-- multiple choices remain after filtering then expand the first space
-- with multiple choices and resume filtering
advancedFilter :: Grid Choices -> [Grid Space]
advancedFilter g
    | isImpossible fg = []
    | isComplete fg   = enumGrids fg
    | otherwise       = concatMap advancedFilter $ expandNonSingle fg
    where
        fg = fix filterChoices g

-------------------------------
-- Grid Construction & Printing
-------------------------------

blank :: Choices
blank = [1..9]

parseGrid :: [String] -> Grid Choices
parseGrid [] = []
parseGrid (r:rs) = parseRow r : parseGrid rs
    where
        parseRow "" = []
        parseRow (c:cs)
            | elem c blanks = blank : parseRow cs
            | isDigit c     = [digitToInt c] : parseRow cs
            | otherwise     = error $ "Invalid character: " ++ show c
        blanks = [' ', '_', '-']

ppGrid :: Grid Space -> IO ()
ppGrid = mapM_ ppRow
    where
        ppRow r = putStrLn $ concat $ intersperse " " $ map show r

ppChoices :: Grid Choices -> IO ()
ppChoices = mapM_ ppRow
    where
        ppRow r = putStrLn $ concat $ intersperse " " $ map showSpace r
        showSpace [n] = show n
        showSpace ns = show ns

printMany :: (a -> IO ()) -> [a] -> IO ()
printMany _ [] = return ()
printMany f (x:xs) = f x
    >> putStrLn "--------------"
    >> printMany f xs

ppManyGrids :: [Grid Space] -> IO ()
ppManyGrids = printMany ppGrid

ppManyChoices :: [Grid Choices] -> IO ()
ppManyChoices = printMany ppChoices

-------------
-- Test Grids
-------------

testEasy :: Grid Choices
testEasy = parseGrid
    [ "6__41_3_8"
    , "815_634__"
    , "73__2__61"
    , "__6157__2"
    , "57_2841_6"
    , "12_396_4_"
    , "3_1_7__8_"
    , "_69_31_5_"
    , "__7_4__1_"
    ]

testExpert :: Grid Choices
testExpert = parseGrid
    [ "_____7_81"
    , "5____4___"
    , "_2___3___"
    , "_8_____73"
    , "_6_______"
    , "__456_2__"
    , "4__8___17"
    , "_1_______"
    , "____9__2_"
    ]

testExpert2 :: Grid Choices
testExpert2 = parseGrid
    [ "_3_6_5__4"
    , "7______3_"
    , "_____4___"
    , "___4_31__"
    , "__9___6__"
    , "8___2____"
    , "________9"
    , "_15____8_"
    , "____9__52"
    ]

worldHardest :: Grid Choices
worldHardest = parseGrid
    [ "8________"
    , "__36_____"
    , "_7__9_2__"
    , "_5___7___"
    , "____457__"
    , "___1___3_"
    , "__1____68"
    , "__85___1_"
    , "_9____4__"
    ]

mainBrute :: Grid Choices -> IO ()
mainBrute = ppGrid . head . bruteForce

mainFilter :: Grid Choices -> IO ()
mainFilter = ppGrid . head . recursiveFilter

mainAdvanced :: Grid Choices -> IO ()
mainAdvanced = ppGrid . head . advancedFilter

main :: IO ()
main = mainAdvanced worldHardest