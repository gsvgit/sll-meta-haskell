module NeighborhoodAnalysis (nan) where

import Data
import DataUtil
import DataIO
import Driving
import Interpreter
import Data.List

nan :: Machine Expr -> Expr -> Expr -> Subst Expr
nan m conf expr = nan' (idContr conf) (buildProcessTree m conf) (buildEvaluationTree m expr)

nan' :: Subst Expr -> Tree Expr -> Tree Expr -> Subst Expr
nan' contr (Node _ (EDecompose _ cts)) (Node _ (EDecompose _ ets)) = 
    foldl1 intersectContr (zipWith (nan' contr) cts ets)
nan' contr (Node _ (ETransient _ ct)) (Node _ (ETransient _ et)) = 
    nan' contr ct et
nan' contr (Node _ (EVariants vs)) (Node _ (ETransient (Just testResult) et)) = 
    nan' (contr /// contr') ct et where (contr', ct) = matchVariant vs testResult
nan' contr (Leaf (Var n _)) (Leaf e) =
    contr /// [(n, e)]
nan' contr _ _ =
    contr
    
matchVariant :: [(Subst Expr, Tree Expr)] -> TestResult -> (Subst Expr, Tree Expr)
matchVariant v (CtrMatch (Pat cn _)) = head [v' | v'@([(_, Ctr n _)], t) <- v, n == cn]
matchVariant [(contr', ct), _] (TestRes True)  = (contr', ct)
matchVariant [_, (contr', ct)] (TestRes False) = (contr', ct)
