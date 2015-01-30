module IRTS.CodegenErlang (codegenErlang) where

import           Idris.Core.TT
import           IRTS.Lang
import           IRTS.CodegenCommon
import           IRTS.Defunctionalise

import           Control.Applicative ((<$>))
import           Control.Monad.Except
import           Control.Monad.Trans.State

import           Data.Char (isPrint, toUpper, isUpper, isLower, isDigit, isAlpha)
import           Data.List (intercalate, insertBy, partition)
import qualified Data.Map.Strict as Map
import           Data.Ord (comparing)

import           System.Directory (getPermissions, setPermissions, setOwnerExecutable)
import           System.Exit (exitSuccess,exitFailure)

-- Everything happens in here. I think. Wait, no, everything actually
-- happens in `generateErl`. This is just a bit of glue code.
codegenErlang :: CodeGenerator
codegenErlang ci = do let outfile = outputFile ci
                      eitherEcg <- runErlCodeGen generateErl (defunDecls ci)
                      case eitherEcg of
                        Left err -> do putStrLn ("Error: " ++ err)
                                       exitFailure
                        Right ecg -> do let erlout = header outfile ++ (Map.elems . forms) ecg ++ [""]
                                        --mapM_ print (decls ecg)
                                        writeFile outfile ("\n" `intercalate` erlout)
                                        p <- getPermissions outfile
                                        setPermissions outfile $ setOwnerExecutable True p

                                        putStrLn ("Compilation Succeeded: " ++ outfile)
                                        exitSuccess

-- Erlang files have to have a `-module().` annotation that matches
-- their filename (without the extension). Given we're making this, we
-- should be curteous and give coders a warning that this file was
-- autogenerated, rather than hand-coded.
header :: String -> [String]
header filename = ["#!/usr/bin/env escript",
                   "%% -*- erlang -*-",
                   "%%! -smp enable",
                   "%% Generated by the Idris -> Erlang Compiler.",
                   "%% Here be dragons.\n",
                   "-module(" ++ modulename ++ ").\n",
                   "-export([main/1]).",
                   "-compile(export_all).",             -- export all top-level functions
                   "-compile(nowarn_unused_function).", -- don't tell me off for not using a fun
                   "-compile(nowarn_unused_vars).",     -- don't tell me off for not using a variable
                   "-compile(nowarn_shadow_vars).",     -- I think DUpdate makes me shadow variables.
                   ""]
  where modulename = takeWhile (/='.') filename

-- Erlang Codegen State Monad
data ErlCodeGen = ECG {
  forms :: Map.Map (String,Int) String, -- name and arity to form
  decls :: [(Name,DDecl)],
  records :: [(Name,Int)],
  locals :: [[(Int, String)]],
  nextLocal :: [Int]
  } deriving (Show)

initECG :: ErlCodeGen
initECG = ECG { forms = Map.empty
              , decls = []
              , records = []
              , locals = []
              , nextLocal = [0]
              }

type ErlCG = StateT ErlCodeGen (ExceptT String IO)

runErlCodeGen :: ([(Name, DDecl)] -> ErlCG ()) -> [(Name,DDecl)] -> IO (Either String ErlCodeGen)
runErlCodeGen ecg ddecls = runExceptT $ execStateT (ecg ddecls) initECG

emitForm :: (String, Int) -> String -> ErlCG ()
emitForm fa form = modify (\ecg -> ecg { forms = Map.insert fa form (forms ecg)})

emitDecl :: Name -> DDecl -> ErlCG ()
emitDecl n d@(DFun _ _ _) = modify (\ecg -> ecg {decls = decls ecg ++ [(n,d)]})
emitDecl _ _ = return ()

addRecord :: Name -> Int -> ErlCG ()
addRecord name arity = do records <- gets records
                          let records1 = insertBy (comparing fst) (name,arity) records
                          modify (\ecg -> ecg { records = records1 })

isRecord :: Name -> ErlCG Bool
isRecord name = do records <- gets records
                   case lookup name records of
                    Just _  -> return True
                    Nothing -> return False

-- We want to be able to compare the length of constructor arguments
-- to the arity of that record constructor, so this returns the
-- arity. If we can't find the record, then -1 is alright to return,
-- as no list will have that length.
recordArity :: Name -> ErlCG Int
recordArity name = do records <- gets records
                      case lookup name records of
                       Just i  -> return i
                       Nothing -> return (-1)

-- OMG Coping with Local variables is a struggle.
--
-- locals is the mapping from (Loc n) to the variable name of that
-- binding. nextLocal is the largest (Loc n) seen at that level of the
-- stack.

popScope :: ErlCG ()
popScope = modify (\ecg -> ecg { locals = tail (locals ecg),
                                 nextLocal = tail (nextLocal ecg) })

pushScope :: ErlCG ()
pushScope = modify (\ecg -> ecg { locals = []:(locals ecg),
                                  nextLocal = 0:(nextLocal ecg) })

pushScopeWithVars :: [String] -> ErlCG ()
pushScopeWithVars vars = modify (\ecg -> ecg { locals = (zipWith (,) [0..] vars):(locals ecg),
                                               nextLocal = (length vars) + (head (nextLocal ecg)):(nextLocal ecg) })

getVar :: LVar -> ErlCG String
getVar (Glob name) = throwError "Oh god, a global"
getVar (Loc i)     = do ls <- gets locals
                        case lookup i (concat ls) of
                         Just var -> return var
                         Nothing  -> throwError "Local Not Found. Oh Fuck."

getNextLocal :: ErlCG String
getNextLocal = do x <- head <$> gets nextLocal
                  modify (\ecg -> ecg {nextLocal = (1+) `toHead` nextLocal ecg})
                  return ("Local" ++ show x)

newLocal :: LVar -> ErlCG String
newLocal (Glob name) = throwError "newLocal on a Global variable"
newLocal (Loc i)     = do getter <- getNextLocal
                          modify (\ecg -> ecg {locals = ((i,getter):) `toHead` locals ecg})
                          return getter

-- This applies f to the head of the list, leaving the tail
-- unchanged. It will blow up if you give it an empty list.
toHead :: (a -> a) -> [a] -> [a]
toHead _ [] = undefined
toHead f (x:xs) = (f x):xs

{- The Code Generator:

Takes in a Name and a DDecl, and hopefully emits some Forms.

Some Definitions:

- Form : the syntax for top-level Erlang function in an Erlang module

- Module : a group of Erlang functions

- Record : Erlang has n-arity tuples, and they're used for
datastructures, in which case it's usual for the first element in the
tuple to be the name of the datastructure. We'll be using these for
most constructors.

More when I realise they're needed.

This first time I'm going to avoid special-casing anything. Later
there are some things I want to special-case to make Erlang interop
easier: - Lists; - 0-Arity Constructors to Atoms (DONE); - Pairs; -
Booleans; - Case Statements that operate only on arguments (erlang has
special syntax for this); - Using Library functions, not Idris' ones;

We emit constructors first, in the hope that we don't need to use all
the constructor functions in favour of just building tuples immediately.
-}

generateErl :: [(Name,DDecl)] -> ErlCG ()
generateErl alldecls = let (ctors, funs) = (isCtor . snd) `partition` alldecls
                       in do emitMain
                             mapM_ (uncurry emitDecl) (ctors++funs)
                             mapM_ (\(_,DConstructor name _ arity) -> generateCtor name arity) ctors
                             mapM_ (\(_,DFun name args exp)        -> generateFun name args exp) funs
  where isCtor (DFun _ _ _) = False
        isCtor (DConstructor _ _ _) = True

generateFun :: Name -> [Name] -> DExp -> ErlCG ()
generateFun name args exp = do pushScopeWithVars args'
                               erlExp <- generateExp exp
                               emitForm (erlAtom name, length args) ((erlAtom name) ++ "(" ++ argsStr ++ ") -> "++ erlExp ++".")
                               popScope
  where args' = map erlVar args
        argsStr = ", " `intercalate` args'

generateCtor :: Name -> Int -> ErlCG ()
generateCtor name arity = addRecord name arity

generateExp :: DExp -> ErlCG String
generateExp (DV lv)            = getVar lv

generateExp (DApp _ name exprs)  = do arity <- recordArity name
                                      exprs' <- mapM generateExp exprs
                                      case arity == length exprs of
                                       True ->  return $ erlTuple ((erlAtom name):exprs')
                                       False -> return $ erlCall (erlAtom name) exprs'

generateExp (DLet vn exp inExp) = do exp' <- generateExp exp
                                     local <- getNextLocal
                                     inExp' <- generateExp inExp
                                     -- storeLocalForName vn local
                                     return $ local ++ " = begin " ++ exp' ++ "end, "++ inExp'

-- These are never generated by the compiler right now
-- generateExp (DUpdate name exp) =
  
-- The tuple is 1-indexed, and its first field is the name of the
-- constructor, which is why we have to add 2 to the index we're given
-- in order to do the correct lookup.
generateExp (DProj exp n)      = do exp' <- generateExp exp
                                    return $ erlCall "element" [show (n+2), exp']

generateExp (DC _ _ name []) = do arity <- recordArity name
                                  case arity of
                                   0 -> return (erlAtom name)
                                   _ -> throwError ("Constructor with wrong arity: 0 vs required " ++ show arity)

generateExp (DC _ _ name exprs) = do arity <- recordArity name
                                     case arity == length exprs of
                                      True -> do exprs' <- mapM generateExp exprs
                                                 return $ erlTuple ((erlAtom name):exprs')
                                      False -> throwError ("Consturctor with wrong arity:" ++ show (length exprs) ++ " vs required " ++ show arity)

generateExp (DCase _  exp alts) = generateCase exp alts
generateExp (DChkCase exp alts) = generateCase exp alts

generateExp (DConst c)          = generateConst c

generateExp (DOp op exprs)      = do exprs' <- mapM generateExp exprs
                                     generatePrim op exprs'

generateExp DNothing            = return "\'nothing\'"
generateExp (DError str)        = return ("erlang:error("++ show str ++")")

generateExp (DForeign _ _ _) = throwError "Foreign Calls not supported"

-- Case Statements
generateCase :: DExp -> [DAlt] -> ErlCG String
generateCase expr alts = do expr' <- generateExp expr
                            alts' <- mapM generateCaseAlt alts
                            return $ "case " ++ expr' ++ " of\n" ++ (";\n" `intercalate` alts') ++ "\nend"

-- Case Statement Clauses
generateCaseAlt :: DAlt -> ErlCG String
generateCaseAlt (DConCase _ name [] expr)   = do pushScope
                                                 expr' <- generateExp expr
                                                 popScope
                                                 return $ (erlAtom name) ++ " -> " ++ expr'
generateCaseAlt (DConCase _ name args expr) = do let args' = map erlVar args
                                                 pushScopeWithVars args'
                                                 expr' <- generateExp expr
                                                 popScope
                                                 return $ "{"++ (", " `intercalate` ((erlAtom name):args')) ++ "} -> " ++ expr'
generateCaseAlt (DConstCase const expr)     = do const' <- generateConst const
                                                 pushScope
                                                 expr' <- generateExp expr
                                                 popScope
                                                 return $ const' ++ " -> " ++ expr'
generateCaseAlt (DDefaultCase expr)         = do pushScope
                                                 expr' <- generateExp expr
                                                 popScope
                                                 return $ "_Default -> " ++ expr'


-- Foreign Calls
-- generateForeign :: FDesc -> FDesc -> [(FDesc,DExp)] -> ErlCG String

-- Some Notes on Constants
--
-- - All Erlang's numbers are arbitrary precision. The VM copes with
-- what size they really are underneath, including whether they're a
-- float.
--
-- - Characters are just numbers. However, there's also a nice syntax
-- for them, which is $<char> is the number of that character. So, if
-- the char is printable, it's best to use the $<char> notation than
-- the number.
--
-- - Strings are actually lists of numbers. However the nicer syntax
-- is within double quotes. Some things will fail, but it's just
-- easier to assume all strings are full of printables, if they're
-- constant.
generateConst :: Const -> ErlCG String
generateConst (I i)  = return $ show i
generateConst (BI i) = return $ show i
generateConst (Fl f) = return $ show f
generateConst (Ch c) | isPrint c = return ['$',c]
                | otherwise = return $ show (fromEnum c)
generateConst (Str s) = return $ show s

generateConst (AType _)  = throwError "TODO: AType: No Idea"
generateConst StrType    = throwError "TODO: StrType: No Idea"
generateConst BufferType = throwError "TODO: BufferType: No Idea"
generateConst PtrType    = throwError "TODO: PtrType"
generateConst ManagedPtrType = throwError "TODO: ManagedPtrType"
generateConst VoidType   = throwError "TODO: VoidType"
generateConst Forgot     = throwError "TODO: Forgot"

generateConst c  = do liftIO . putStrLn $ "No Const: " ++ (show c)
                      throwError "TODO: Finish generateConst for buffer types"

-- Some Notes on Primitive Operations
--
-- - Official Docs:
-- http://www.erlang.org/doc/reference_manual/expressions.html#id78907
-- http://www.erlang.org/doc/reference_manual/expressions.html#id78646
--
-- - Oh look, because we only have one number type, all mathematical
-- operations are really easy. The only thing to note is this: `div`
-- is explicitly integer-only, so is worth using whenever integer
-- division is asked for (to avoid everything becoming floaty). '/' is
-- for any number, so we just use that on floats.
--
--
generatePrim :: PrimFn -> [String] -> ErlCG String
generatePrim (LPlus _)       [x,y] = return $ erlBinOp "+" x y
generatePrim (LMinus _)      [x,y] = return $ erlBinOp "-" x y
generatePrim (LTimes _)      [x,y] = return $ erlBinOp "*" x y
generatePrim (LUDiv _)       [x,y] = return $ erlBinOp "div" x y
generatePrim (LSDiv ATFloat) [x,y] = return $ erlBinOp "/" x y
generatePrim (LSDiv _)       [x,y] = return $ erlBinOp "div" x y
generatePrim (LURem _)       [x,y] = return $ erlBinOp "rem" x y
generatePrim (LSRem _)       [x,y] = return $ erlBinOp "rem" x y
generatePrim (LAnd _)        [x,y] = return $ erlBinOp "band" x y
generatePrim (LOr _)         [x,y] = return $ erlBinOp "bor" x y
generatePrim (LXOr _)        [x,y] = return $ erlBinOp "bxor" x y
generatePrim (LCompl _)      [x]   = return $ erlBinOp "bnot" "" x  -- hax
generatePrim (LSHL _)        [x,y] = return $ erlBinOp "bsl" x y
generatePrim (LASHR _)       [x,y] = return $ erlBinOp "bsr" x y
generatePrim (LLSHR _)       [x,y] = return $ erlBinOp "bsr" x y -- using an arithmetic shift when we should use a logical one.
generatePrim (LEq _)         [x,y] = return $ erlBinOp "=:=" x y
generatePrim (LLt _)         [x,y] = return $ erlBinOp "<" x y
generatePrim (LLe _)         [x,y] = return $ erlBinOp "=<" x y
generatePrim (LGt _)         [x,y] = return $ erlBinOp ">" x y
generatePrim (LGe _)         [x,y] = return $ erlBinOp ">=" x y
generatePrim (LSLt _)        [x,y] = return $ erlBinOp "<" x y
generatePrim (LSLe _)        [x,y] = return $ erlBinOp "=<" x y
generatePrim (LSGt _)        [x,y] = return $ erlBinOp ">" x y
generatePrim (LSGe _)        [x,y] = return $ erlBinOp ">=" x y
generatePrim (LSExt _ _)     [x]   = return $ x -- Not sure if correct
generatePrim (LZExt _ _)     [x]   = return $ x -- Not sure if correct
generatePrim (LTrunc _ _)    [x]   = return $ x -- Not sure if correct

generatePrim (LIntFloat _)   [x]   = return $ erlBinOp "+" x "0.0"
generatePrim (LFloatInt _)   [x]   = return $ erlCall "trunc" [x]
generatePrim (LIntStr _)     [x]   = return $ erlCall "integer_to_list" [x]
generatePrim (LStrInt _)     [x]   = return $ erlCall "list_to_integer" [x]
generatePrim (LFloatStr)     [x]   = return $ erlCall "float_to_list" [x, "[compact, {decimals, 20}]"]
generatePrim (LStrFloat)     [x]   = return $ erlCall "list_to_float" [x]
generatePrim (LChInt _)      [x]   = return $ x -- Chars are just Integers anyway.
generatePrim (LIntCh _)      [x]   = return $ x
generatePrim (LBitCast _ _)  [x]   = return $ x

generatePrim (LFExp)         [x]   = return $ erlCallMFA "math" "exp" [x]
generatePrim (LFLog)         [x]   = return $ erlCallMFA "math" "log" [x]
generatePrim (LFSin)         [x]   = return $ erlCallMFA "math" "sin" [x]
generatePrim (LFCos)         [x]   = return $ erlCallMFA "math" "cos" [x]
generatePrim (LFTan)         [x]   = return $ erlCallMFA "math" "tan" [x]
generatePrim (LFASin)        [x]   = return $ erlCallMFA "math" "asin" [x]
generatePrim (LFACos)        [x]   = return $ erlCallMFA "math" "acos" [x]
generatePrim (LFATan)        [x]   = return $ erlCallMFA "math" "atan" [x]
generatePrim (LFSqrt)        [x]   = return $ erlCallMFA "math" "sqrt" [x]
generatePrim (LFFloor)       [x]   = emitCeil >> erlCallIRTS "ceil" [x]
generatePrim (LFCeil)        [x]   = emitFloor >> erlCallIRTS "floor" [x]
generatePrim (LFNegate)      [x]   = return $ "-" ++ x

generatePrim (LMkVec _ _)     _    = throwError "Vector Primitives Not Supported in Erlang"
generatePrim (LIdxVec _ _)    _    = throwError "Vector Primitives Not Supported in Erlang"
generatePrim (LUpdateVec _ _) _    = throwError "Vector Primitives Not Supported in Erlang"

generatePrim (LStrHead)      [x]   = return $ erlCall "hd" [x]
generatePrim (LStrTail)      [x]   = return $ erlCall "tl" [x]
generatePrim (LStrCons)      [x,y] = return $ "["++x++"|"++y++"]"
generatePrim (LStrIndex)     [x,y] = emitStrIndex >> erlCallIRTS "str_index" [x,y]
generatePrim (LStrNull)      [_,x] = emitStrNull >> erlCallIRTS "str_null" [x]
generatePrim (LStrRev)       [x]   = return $ erlCallMFA "lists" "reverse" [x]
generatePrim (LStrConcat)    [x,y] = return $ erlBinOp "++" x y
generatePrim (LStrLt)        [x,y] = return $ erlBinOp "<" x y
generatePrim (LStrEq)        [x,y] = return $ erlBinOp "=:=" x y
generatePrim (LStrLen)       [x]   = return $ erlCall "length" [x]

generatePrim (LPrintStr)     [_,h,s] = emitPrintStr >> erlCallIRTS "print_str" [h,s]
generatePrim (LReadStr)      [_,h]   = emitReadStr >> erlCallIRTS "read_str" [h]
generatePrim (LReadChar)     [_,h]   = emitReadChr >> erlCallIRTS "read_chr" [h]

generatePrim (LFileOpen)     [_,f,m] = emitFileOpen >> erlCallIRTS "file_open" [f,m] 
generatePrim (LFileClose)    [_,h]   = emitFileClose >> erlCallIRTS "file_close" [h]
generatePrim (LFileFlush)    [_,h]   = emitFileFlush >> erlCallIRTS "file_flush" [h]
generatePrim (LFileEOF)      [_,h]   = emitFileEOF >> erlCallIRTS "file_eof" [h]
generatePrim (LFileError)    [_,h]   = emitFileError >> erlCallIRTS "file_error" [h]
generatePrim (LFilePoll)     [_,h]   = emitFilePoll >> erlCallIRTS "file_poll" [h]
generatePrim (LStdIn)         _    = return $ "standard_io"
generatePrim (LStdOut)        _    = return $ "standard_io"
generatePrim (LStdErr)        _    = return $ "standard_error"
generatePrim (LPOpen)         _    = throwError "Popen not supported"
generatePrim (LPClose)        _    = throwError "Popen not supported"

generatePrim (LAllocate)      _    = throwError "Allocation not supported"
generatePrim (LAppendBuffer)  _    = throwError "Buffers not supported"
generatePrim (LSystemInfo)    _    = throwError "System Info not supported"
generatePrim (LForceGC)       _    = return $ erlCallMFA "erlang" "garbage_collect" []

generatePrim (LAppend _ _)    _    = throwError "Buffers not supported"
generatePrim (LPeek _ _)      _    = throwError "Buffers not supported"

generatePrim (LFork)          _    = throwError "Fork not supported"
generatePrim (LPar)          [x]   = return x

generatePrim (LNullPtr)       _    = return $ "undefined"
generatePrim (LVMPtr)         _    = return $ "undefined"
generatePrim (LPtrNull)      [_,p] = emitPtrNull >> erlCallIRTS "ptr_null" [p]
generatePrim (LPtrEq)        [_,p1,p2] = emitPtrEq >> erlCallIRTS "ptr_eq" [p1,p2]

generatePrim p a = do liftIO . putStrLn $ "No Primitive: " ++ show p ++ " on " ++ show (length a) ++ " args."
                      throwError "generatePrim: Unknown Op, or incorrect arity"


erlBinOp :: String -> String -> String -> String
erlBinOp op a b = concat ["(",a," ",op," ",b,")"]

-- Erlang Atoms can contain quite a lot of chars, so let's see how they cope
erlAtom :: Name -> String
erlAtom n = strAtom (showCG n)

strAtom :: String -> String
strAtom s = "\'" ++ concatMap atomchar s ++ "\'"
  where atomchar x | x == '\'' = "\\'"
                   | x == '\\' = "\\\\"
                   | x == '.' = "_"
                   | x `elem` "{}" = ""
                   | isPrint x = [x]
                   | otherwise = "_" ++ show (fromEnum x) ++ "_"


-- Erlang Variables have a more restricted set of chars, and must
-- start with a capital letter (erased can start with an underscore)
erlVar :: Name -> String
erlVar NErased = "_Erased"
erlVar n = capitalize (concatMap varchar (showCG n))
  where varchar x | isAlpha x = [x]
                  | isDigit x = [x]
                  | x == '_'  = "_"
                  | x `elem` "{}" = "" -- I hate the {}, and they fuck up everything.
                  | otherwise = "_" ++ show (fromEnum x) ++ "_"
        capitalize [] = []
        capitalize (x:xs) | isUpper x = x:xs
                          | isLower x = (toUpper x):xs
                          | otherwise = 'V':x:xs

erlTuple :: [String] -> String
erlTuple elems = "{" ++ (", " `intercalate` elems) ++ "}"

erlCall :: String -> [String] -> String
erlCall fun args = fun ++ "("++ (", " `intercalate` args) ++")"

erlCallMFA :: String -> String -> [String] -> String
erlCallMFA mod fun args = mod ++ ":" ++ erlCall fun args

erlCallIRTS :: String -> [String] -> ErlCG String
erlCallIRTS f a = return $ erlCall f a


{-

This code is a bit horrendous. It just adds some forms for the
operations that the code is using.

They're all wrappers, and all pretty ugly.

-}

emitMain :: ErlCG ()
emitMain = emitForm ("main", 1) "main(_Args) ->\
                                \    runMain0(),\
                                \    halt(0)."

emitFloor :: ErlCG ()
emitFloor = emitForm ("floor", 1) "floor(X) when X < 0 ->\
                                  \    T = trunc(X),\
                                  \    case X - T == 0 of\
                                  \        true -> T; \
                                  \        false -> T - 1\
                                  \    end;\
                                  \floor(X) ->\
                                  \    trunc(X)."

emitCeil :: ErlCG ()
emitCeil = emitForm ("ceil", 1) "ceil(X) when X < 0 -> \
                                \    trunc(X); \
                                \ceil(X) -> \
                                \    T = trunc(X), \
                                \    case X - T == 0 of \
                                \        true -> T; \
                                \        false -> T + 1 \
                                \    end."

emitStrIndex :: ErlCG ()
emitStrIndex = emitForm ("str_index", 2) "str_index(Str, Idx) ->\
                                         \    lists:nth(Idx+1, Str)."

emitStrNull :: ErlCG ()
emitStrNull = emitForm ("str_null", 1) "str_null([]) ->\
                                       \    0;\
                                       \str_null(_) ->\
                                       \    1."

emitPtrNull :: ErlCG ()
emitPtrNull = emitForm ("ptr_null", 1) "ptr_null(undefined) ->\
                                       \    0;\
                                       \ptr_null(_) ->\
                                       \    1."

emitPtrEq :: ErlCG ()
emitPtrEq = emitForm ("ptr_eq", 1) "ptr_eq(A,B) ->\
                                   \    case A =:= B of\
                                   \        true -> 0;\
                                   \        false -> 1\
                                   \    end."

emitPrintStr :: ErlCG ()
emitPrintStr = emitForm ("print_str", 2) "print_str(undefined, _) ->\
                                         \    1;\
                                         \print_str(Handle, Str) ->\
                                         \    case file:write(Handle, Str) of\
                                         \        ok -> 0;\
                                         \        _ -> 1\
                                         \    end."

emitReadStr :: ErlCG ()
emitReadStr = emitForm ("read_str", 1) "read_str(undefined) ->\
                                       \    \"\";\
                                       \read_str(Handle) ->\
                                       \    case file:read_line(Handle) of\
                                       \        {ok, Data} -> Data;\
                                       \        _ -> \"\"\
                                       \    end."

emitReadChr :: ErlCG ()
emitReadChr = emitForm ("read_chr", 1) "read_chr(undefined) ->\
                                       \    -1;\
                                       \read_chr(Handle) ->\
                                       \    case file:read(Handle, 1) of\
                                       \        {ok, [Chr]} -> Chr;\
                                       \        _ -> -1\
                                       \    end."

emitFileOpen :: ErlCG ()
emitFileOpen = emitForm ("file_open", 2) "file_open(Name, Mode) ->\
                                         \    ModeOpts = case Mode of\
                                         \                   \"r\" ->  [read];\
                                         \                   \"w\" ->  [write];\
                                         \                   \"r+\" -> [read, write]\
                                         \               end,\
                                         \    case file:open(Name, ModeOpts) of\
                                         \        {ok, Handle} -> Handle;\
                                         \        _ -> undefined\
                                         \    end."

emitFileClose :: ErlCG ()
emitFileClose = emitForm ("file_close", 1) "file_close(undefined) ->\
                                           \    0;\
                                           \file_close(Handle) ->\
                                           \    case file:close(Handle) of\ 
                                           \        ok -> 0;\
                                           \        _ -> 1\
                                           \    end."

emitFileFlush :: ErlCG ()
emitFileFlush = emitForm ("file_flush", 1) "file_flush(undefined) ->\
                                           \    0;\
                                           \file_flush(Handle) -> \
                                           \    case file:sync(Handle) of\
                                           \        ok -> 0;\
                                           \        _ -> -1\
                                           \    end."

emitFileEOF :: ErlCG ()
emitFileEOF = emitForm ("file_eof", 1) "file_eof(undefined) ->\
                                       \    0;\
                                       \file_eof(Handle) ->\
                                       \    case file:read(Handle,1) of\
                                       \        eof -> 0;\
                                       \        {ok, _} -> case file:position(Handle, {cur, -1}) of\
                                       \                       {ok, _} -> -1;\
                                       \                       {error, _} -> 0\
                                       \                   end;\
                                       \        {error, _} -> 0\
                                       \    end."

emitFileError :: ErlCG ()
emitFileError = emitForm ("file_error", 1) "file_error(undefined) ->\
                                           \    0;\
                                           \file_error(_Handle) ->\
                                           \    0."
emitFilePoll :: ErlCG ()
emitFilePoll = emitForm ("file_poll", 1) "file_poll(_Handle) -> 0."
