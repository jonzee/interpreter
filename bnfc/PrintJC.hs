{-# OPTIONS_GHC -fno-warn-incomplete-patterns #-}
module PrintJC where

-- pretty-printer generated by the BNF converter

import AbsJC
import Data.Char


-- the top-level printing method
printTree :: Print a => a -> String
printTree = render . prt 0

type Doc = [ShowS] -> [ShowS]

doc :: ShowS -> Doc
doc = (:)

render :: Doc -> String
render d = rend 0 (map ($ "") $ d []) "" where
  rend i ss = case ss of
    "["      :ts -> showChar '[' . rend i ts
    "("      :ts -> showChar '(' . rend i ts
    "{"      :ts -> showChar '{' . new (i+1) . rend (i+1) ts
    "}" : ";":ts -> new (i-1) . space "}" . showChar ';' . new (i-1) . rend (i-1) ts
    "}"      :ts -> new (i-1) . showChar '}' . new (i-1) . rend (i-1) ts
    ";"      :ts -> showChar ';' . new i . rend i ts
    t  : "," :ts -> showString t . space "," . rend i ts
    t  : ")" :ts -> showString t . showChar ')' . rend i ts
    t  : "]" :ts -> showString t . showChar ']' . rend i ts
    t        :ts -> space t . rend i ts
    _            -> id
  new i   = showChar '\n' . replicateS (2*i) (showChar ' ') . dropWhile isSpace
  space t = showString t . (\s -> if null s then "" else ' ':s)

parenth :: Doc -> Doc
parenth ss = doc (showChar '(') . ss . doc (showChar ')')

concatS :: [ShowS] -> ShowS
concatS = foldr (.) id

concatD :: [Doc] -> Doc
concatD = foldr (.) id

replicateS :: Int -> ShowS -> ShowS
replicateS n f = concatS (replicate n f)

-- the printer class does the job
class Print a where
  prt :: Int -> a -> Doc
  prtList :: Int -> [a] -> Doc
  prtList i = concatD . map (prt i)

instance Print a => Print [a] where
  prt = prtList

instance Print Char where
  prt _ s = doc (showChar '\'' . mkEsc '\'' s . showChar '\'')
  prtList _ s = doc (showChar '"' . concatS (map (mkEsc '"') s) . showChar '"')

mkEsc :: Char -> Char -> ShowS
mkEsc q s = case s of
  _ | s == q -> showChar '\\' . showChar s
  '\\'-> showString "\\\\"
  '\n' -> showString "\\n"
  '\t' -> showString "\\t"
  _ -> showChar s

prPrec :: Int -> Int -> Doc -> Doc
prPrec i j = if j<i then parenth else id


instance Print Integer where
  prt _ x = doc (shows x)


instance Print Double where
  prt _ x = doc (shows x)


instance Print Ident where
  prt _ (Ident i) = doc (showString ( i))
  prtList _ [] = (concatD [])
  prtList _ [x] = (concatD [prt 0 x])
  prtList _ (x:xs) = (concatD [prt 0 x, doc (showString ","), prt 0 xs])


instance Print Program where
  prt i e = case e of
    Pro exps -> prPrec i 0 (concatD [prt 0 exps])

instance Print Exp where
  prt i e = case e of
    EBlock exps -> prPrec i 0 (concatD [doc (showString "{"), prt 0 exps, doc (showString "}")])
    EIfStmt exp1 exp2 -> prPrec i 0 (concatD [doc (showString "if"), doc (showString "("), prt 0 exp1, doc (showString ")"), prt 0 exp2])
    EIfElse exp1 exp2 exp3 -> prPrec i 0 (concatD [doc (showString "if"), doc (showString "("), prt 0 exp1, doc (showString ")"), prt 0 exp2, doc (showString "else"), prt 0 exp3])
    EWhile exp1 exp2 -> prPrec i 0 (concatD [doc (showString "while"), doc (showString "("), prt 0 exp1, doc (showString ")"), prt 0 exp2])
    EForLoo exps exp -> prPrec i 0 (concatD [doc (showString "for"), doc (showString "("), prt 0 exps, doc (showString ")"), prt 0 exp])
    EDecEmp id -> prPrec i 0 (concatD [doc (showString "var"), prt 0 id])
    EDecVar id exp -> prPrec i 0 (concatD [doc (showString "var"), prt 0 id, doc (showString "="), prt 0 exp])
    EDecAno ids exp -> prPrec i 0 (concatD [doc (showString "fun"), doc (showString "("), prt 0 ids, doc (showString ")"), prt 12 exp])
    EDecFun id ids exp -> prPrec i 0 (concatD [doc (showString "fun"), prt 0 id, doc (showString "("), prt 0 ids, doc (showString ")"), prt 12 exp])
    EFun exp exps -> prPrec i 10 (concatD [prt 10 exp, doc (showString "("), prt 0 exps, doc (showString ")")])
    EFunExp exps -> prPrec i 12 (concatD [doc (showString "{"), prt 0 exps, doc (showString "}")])
    EReturn exp -> prPrec i 10 (concatD [doc (showString "return"), prt 0 exp])
    EToStr exp -> prPrec i 10 (concatD [doc (showString "str"), doc (showString "("), prt 0 exp, doc (showString ")")])
    EToInt exp -> prPrec i 10 (concatD [doc (showString "int"), doc (showString "("), prt 0 exp, doc (showString ")")])
    EPrint exp -> prPrec i 0 (concatD [doc (showString "print"), doc (showString "("), prt 0 exp, doc (showString ")"), doc (showString ";")])
    EAss exp1 assop exp2 -> prPrec i 0 (concatD [prt 9 exp1, prt 0 assop, prt 0 exp2])
    EElem id exp -> prPrec i 10 (concatD [prt 0 id, doc (showString "["), prt 0 exp, doc (showString "]")])
    EPre ssym exp -> prPrec i 9 (concatD [prt 0 ssym, prt 9 exp])
    EPreOp unaop exp -> prPrec i 9 (concatD [prt 0 unaop, prt 8 exp])
    EPost exp ssym -> prPrec i 10 (concatD [prt 10 exp, prt 0 ssym])
    ELor exp1 exp2 -> prPrec i 1 (concatD [prt 1 exp1, doc (showString "||"), prt 2 exp2])
    EAnd exp1 exp2 -> prPrec i 2 (concatD [prt 2 exp1, doc (showString "&&"), prt 3 exp2])
    EEqu exp1 exp2 -> prPrec i 3 (concatD [prt 3 exp1, doc (showString "=="), prt 4 exp2])
    ENeq exp1 exp2 -> prPrec i 3 (concatD [prt 3 exp1, doc (showString "!="), prt 4 exp2])
    ELrt exp1 exp2 -> prPrec i 4 (concatD [prt 4 exp1, doc (showString "<"), prt 5 exp2])
    EGrt exp1 exp2 -> prPrec i 4 (concatD [prt 4 exp1, doc (showString ">"), prt 5 exp2])
    EAdd exp1 exp2 -> prPrec i 6 (concatD [prt 6 exp1, doc (showString "+"), prt 7 exp2])
    ESub exp1 exp2 -> prPrec i 6 (concatD [prt 6 exp1, doc (showString "-"), prt 7 exp2])
    EMul exp1 exp2 -> prPrec i 7 (concatD [prt 7 exp1, doc (showString "*"), prt 8 exp2])
    EDiv exp1 exp2 -> prPrec i 7 (concatD [prt 7 exp1, doc (showString "/"), prt 8 exp2])
    ENil -> prPrec i 11 (concatD [doc (showString "nil")])
    EBool boolean -> prPrec i 11 (concatD [prt 0 boolean])
    EInt n -> prPrec i 11 (concatD [prt 0 n])
    EStr str -> prPrec i 11 (concatD [prt 0 str])
    EVar id -> prPrec i 11 (concatD [prt 0 id])
    EArr exps -> prPrec i 0 (concatD [doc (showString "["), prt 0 exps, doc (showString "]")])
  prtList _ [] = (concatD [])
  prtList _ [] = (concatD [])
  prtList _ [x] = (concatD [prt 0 x])
  prtList _ (x:xs) = (concatD [prt 0 x, prt 0 xs])
  prtList _ (x:xs) = (concatD [prt 0 x, doc (showString ";"), prt 0 xs])
instance Print SSym where
  prt i e = case e of
    SInc -> prPrec i 0 (concatD [doc (showString "++")])
    SDec -> prPrec i 0 (concatD [doc (showString "--")])

instance Print Boolean where
  prt i e = case e of
    BTrue -> prPrec i 0 (concatD [doc (showString "true")])
    BFalse -> prPrec i 0 (concatD [doc (showString "false")])

instance Print AssOp where
  prt i e = case e of
    ASgn -> prPrec i 0 (concatD [doc (showString "=")])
    AMul -> prPrec i 0 (concatD [doc (showString "*=")])
    ADiv -> prPrec i 0 (concatD [doc (showString "/=")])
    AAdd -> prPrec i 0 (concatD [doc (showString "+=")])
    ASub -> prPrec i 0 (concatD [doc (showString "-=")])

instance Print UnaOp where
  prt i e = case e of
    Poz -> prPrec i 0 (concatD [doc (showString "+")])
    Neg -> prPrec i 0 (concatD [doc (showString "-")])
    LNe -> prPrec i 0 (concatD [doc (showString "!")])

