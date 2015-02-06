%% -*- erlang -*-
%%! -smp enable
%% Generated by the Idris -> Erlang Compiler.
%% Here be dragons.

-module(main).

-mode(compile). %% Escript
-export([main/1]). %% Escript.
-compile(export_all).
-compile(nowarn_unused_function).
-compile(nowarn_unused_vars).
-define(TRUE, 1).
-define(FALSE, 0).

'APPLY0'(Fn0, Arg0) -> case Fn0 of
'U_Main_main01' -> 'Main_main0'(Arg0);
{'U_Main_testFiles01', P_c0} -> 'Main_testFiles0'(P_c0, Arg0);
'U_Main_testFiles101' -> 'Main_testFiles10'(Arg0);
'U_Main_testFiles11' -> 'Main_testFiles1'(Arg0);
'U_Main_testFiles21' -> 'Main_testFiles2'(Arg0);
{'U_Main_testFiles31', P_c0} -> 'Main_testFiles3'(P_c0, Arg0);
{'U_Main_testFiles41', P_c0} -> 'Main_testFiles4'(P_c0, Arg0);
{'U_Main_testFiles51', P_c0} -> 'Main_testFiles5'(P_c0, Arg0);
{'U_Main_testFiles61', P_c0} -> 'Main_testFiles6'(P_c0, Arg0);
{'U_Main_testFiles71', P_c0} -> 'Main_testFiles7'(P_c0, Arg0);
{'U_Main_testFiles81', P_c0} -> 'Main_testFiles8'(P_c0, Arg0);
'U_Main_testFiles91' -> 'Main_testFiles9'(Arg0);
'U_Main_testStrings01' -> 'Main_testStrings0'(Arg0);
'U_Main_testStrings11' -> 'Main_testStrings1'(Arg0);
'U_Main_testStrings21' -> 'Main_testStrings2'(Arg0);
{'U_Prelude_Classes_Int instance of Prelude_Classes_Eq1', P_c0} -> 'Prelude_Classes_@Prelude_Classes_Eq$Int'(P_c0, Arg0);
'U_Prelude_closeFile01' -> 'Prelude_closeFile0'(Arg0);
'U_Prelude_feof01' -> 'Prelude_feof0'(Arg0);
'U_Prelude_fgetc01' -> 'Prelude_fgetc0'(Arg0);
'U_Prelude_fopen01' -> 'Prelude_fopen0'(Arg0);
'U_Prelude_fwrite01' -> 'Prelude_fwrite0'(Arg0);
'U_Prelude_nullStr01' -> 'Prelude_nullStr0'(Arg0);
{'U_io_bind1', P_c0, P_c1, P_c2, P_c3, P_c4} -> 'io_bind'(P_c0, P_c1, P_c2, P_c3, P_c4, Arg0);
{'U_io_return1', P_c0, P_c1, P_c2} -> 'io_return'(P_c0, P_c1, P_c2, Arg0);
{'U_prim_fclose1', P_c0} -> 'prim_fclose'(P_c0, Arg0);
{'U_prim_feof1', P_c0} -> 'prim_feof'(P_c0, Arg0);
{'U_prim_fgetc1', P_c0} -> 'prim_fgetc'(P_c0, Arg0);
{'U_prim_fopen1', P_c0, P_c1} -> 'prim_fopen'(P_c0, P_c1, Arg0);
{'U_prim_fprint1', P_c0, P_c1} -> 'prim_fprint'(P_c0, P_c1, Arg0);
{'U_prim_fread1', P_c0} -> 'prim_fread'(P_c0, Arg0);
{'U_prim_strIsNull1', P_c0} -> 'prim_strIsNull'(P_c0, Arg0);
{'U_io_bind11', P_c0, P_c1, P_c2, P_c3, P_c4, P_c5} -> 'io_bind1'(P_c0, P_c1, P_c2, P_c3, P_c4, P_c5, Arg0);
'U_Prelude_Classes_Int instance of Prelude_Classes_Eq2' -> {'U_Prelude_Classes_Int instance of Prelude_Classes_Eq1', Arg0};
_Default -> undefined
end.
'EVAL0'(Arg0) -> case Arg0 of
_Default -> Arg0
end.
'Force'(E0, E1, E2) -> In0 = begin 'EVAL0'(E2)end, In0.
'Main_main'() -> {'U_io_bind1', undefined, undefined, undefined, 'Main_testFiles'(), 'U_Main_main01'}.
'Main_main0'(In0) -> 'Main_testStrings'().
'Main_testFiles'() -> {'U_io_bind1', undefined, undefined, undefined, 'Prelude_fwrite'('prim__stdout'(), "testFiles\n"), 'U_Main_testFiles101'}.
'Main_testFiles0'(In9, In10) -> 'Prelude_closeFile'(In9).
'Main_testFiles1'(In9) -> {'U_io_bind1', undefined, undefined, undefined, 'Prelude_fwrite'(In9, "test"), {'U_Main_testFiles01', In9}}.
'Main_testFiles10'(In0) -> {'U_io_bind1', undefined, undefined, undefined, 'Prelude_fopen'("test_file", "r"), 'U_Main_testFiles91'}.
'Main_testFiles2'(In8) -> {'U_io_bind1', undefined, undefined, undefined, 'Prelude_fopen'("other_file", "w"), 'U_Main_testFiles11'}.
'Main_testFiles3'(In1, In7) -> {'U_io_bind1', undefined, undefined, undefined, 'Prelude_closeFile'(In1), 'U_Main_testFiles21'}.
'Main_testFiles4'(In1, In6) -> {'U_io_bind1', undefined, undefined, undefined, case In6 of
'Prelude_Bool_False' -> 'Prelude_fwrite'('prim__stdout'(), "Not EOF\n");
'Prelude_Bool_True' -> 'Prelude_fwrite'('prim__stdout'(), "EOF\n")
end, {'U_Main_testFiles31', In1}}.
'Main_testFiles5'(In1, In5) -> {'U_io_bind1', undefined, undefined, undefined, 'Prelude_feof'(In1), {'U_Main_testFiles41', In1}}.
'Main_testFiles6'(In1, In4) -> {'U_io_bind1', undefined, undefined, undefined, 'Prelude_fwrite'('prim__stdout'(), (("read from file: " ++ In4) ++ "\n")), {'U_Main_testFiles51', In1}}.
'Main_testFiles7'(In1, In3) -> {'U_io_bind1', undefined, undefined, undefined, {'U_prim_fread1', In1}, {'U_Main_testFiles61', In1}}.
'Main_testFiles8'(In1, In2) -> {'U_io_bind1', undefined, undefined, undefined, 'Prelude_fwrite'('prim__stdout'(), (("read char from file: " ++ [In2|""]) ++ "\n")), {'U_Main_testFiles71', In1}}.
'Main_testFiles9'(In1) -> {'U_io_bind1', undefined, undefined, undefined, 'Prelude_fgetc'(In1), {'U_Main_testFiles81', In1}}.
'Main_testStrings'() -> {'U_io_bind1', undefined, undefined, undefined, 'Prelude_fwrite'('prim__stdout'(), "testStrings\n"), 'U_Main_testStrings21'}.
'Main_testStrings0'(In2) -> case In2 of
'Prelude_Bool_False' -> 'Prelude_fwrite'('prim__stdout'(), "not null\n");
'Prelude_Bool_True' -> 'Prelude_fwrite'('prim__stdout'(), "null\n")
end.
'Main_testStrings1'(In1) -> {'U_io_bind1', undefined, undefined, undefined, 'Prelude_nullStr'(In1), 'U_Main_testStrings01'}.
'Main_testStrings2'(In0) -> {'U_io_bind1', undefined, undefined, undefined, {'U_io_return1', undefined, undefined, ""}, 'U_Main_testStrings11'}.
'Prelude_Bool_boolElim'(E0, E1, E2, E3) -> case E1 of
'Prelude_Bool_False' -> 'EVAL0'(E3);
'Prelude_Bool_True' -> 'EVAL0'(E2)
end.
'Prelude_Bool_not'(E0) -> case E0 of
'Prelude_Bool_False' -> 'Prelude_Bool_True';
'Prelude_Bool_True' -> 'Prelude_Bool_False'
end.
'Prelude_Classes_=='(E0, E1) -> E1.
'Prelude_Classes_@Prelude_Classes_Eq$Int'(Meth0, Meth1) -> case bool_cast((Meth0 =:= Meth1)) of
0 -> 'Prelude_Bool_False';
_Default -> 'Prelude_Bool_True'
end.
'Prelude_Classes_intToBool'(E0) -> case E0 of
0 -> 'Prelude_Bool_False';
_Default -> 'Prelude_Bool_True'
end.
'Prelude_closeFile'(E0) -> {'U_io_bind1', undefined, undefined, undefined, {'U_prim_fclose1', E0}, 'U_Prelude_closeFile01'}.
'Prelude_closeFile0'(In0) -> {'U_io_return1', undefined, undefined, 'MkUnit'}.
'Prelude_feof'(E0) -> {'U_io_bind1', undefined, undefined, undefined, {'U_prim_feof1', E0}, 'U_Prelude_feof01'}.
'Prelude_feof0'(In0) -> {'U_io_return1', undefined, undefined, case case bool_cast((In0 =:= 0)) of
0 -> 'Prelude_Bool_False';
_Default -> 'Prelude_Bool_True'
end of
'Prelude_Bool_False' -> 'Prelude_Bool_True';
'Prelude_Bool_True' -> 'Prelude_Bool_False'
end}.
'Prelude_fgetc'(E0) -> {'U_io_bind1', undefined, undefined, undefined, {'U_prim_fgetc1', E0}, 'U_Prelude_fgetc01'}.
'Prelude_fgetc0'(In0) -> {'U_io_return1', undefined, undefined, In0}.
'Prelude_fopen'(E0, E1) -> {'U_io_bind1', undefined, undefined, undefined, {'U_prim_fopen1', E0, E1}, 'U_Prelude_fopen01'}.
'Prelude_fopen0'(In0) -> {'U_io_return1', undefined, undefined, In0}.
'Prelude_fread'(E0) -> {'U_prim_fread1', E0}.
'Prelude_fwrite'(E0, E1) -> {'U_io_bind1', undefined, undefined, undefined, {'U_prim_fprint1', E0, E1}, 'U_Prelude_fwrite01'}.
'Prelude_fwrite0'(In0) -> {'U_io_return1', undefined, undefined, 'MkUnit'}.
'Prelude_nullStr'(E0) -> {'U_io_bind1', undefined, undefined, undefined, {'U_prim_strIsNull1', E0}, 'U_Prelude_nullStr01'}.
'Prelude_nullStr0'(In0) -> {'U_io_return1', undefined, undefined, case 'APPLY0'('APPLY0'('Prelude_Classes_=='(undefined, 'U_Prelude_Classes_Int instance of Prelude_Classes_Eq2'), In0), 0) of
'Prelude_Bool_False' -> 'Prelude_Bool_True';
'Prelude_Bool_True' -> 'Prelude_Bool_False'
end}.
'io_bind'(E0, E1, E2, E3, E4, W) -> 'APPLY0'('io_bind2'(E0, E1, E2, E3, E4, W), 'APPLY0'(E3, W)).
'io_bind0'(E0, E1, E2, E3, E4, W, In0) -> 'APPLY0'(E4, In0).
'io_bind1'(E0, E1, E2, E3, E4, W, In0) -> 'APPLY0'('io_bind0'(E0, E1, E2, E3, E4, W, In0), W).
'io_bind2'(E0, E1, E2, E3, E4, W) -> {'U_io_bind11', E0, E1, E2, E3, E4, W}.
'io_bind_case'(E0, E1, E2, E3, E4, E5, E6, E7) -> 'APPLY0'(E7, E5).
'io_return'(E0, E1, E2, W) -> E2.
'prim__concat'(Op0, Op1) -> (Op0 ++ Op1).
'prim__eqInt'(Op0, Op1) -> bool_cast((Op0 =:= Op1)).
'prim__fileClose'(Op0, Op1) -> file_close(Op1).
'prim__fileEOF'(Op0, Op1) -> file_eof(Op1).
'prim__fileOpen'(Op0, Op1, Op2) -> file_open(Op1, Op2).
'prim__intToChar'(Op0) -> Op0.
'prim__printString'(Op0, Op1, Op2) -> print_str(Op1, Op2).
'prim__readChar'(Op0, Op1) -> read_chr(Op1).
'prim__readString'(Op0, Op1) -> read_str(Op1).
'prim__stdout'() -> standard_io.
'prim__strCons'(Op0, Op1) -> [Op0|Op1].
'prim__strIsNull'(Op0, Op1) -> str_null(Op1).
'prim_fclose'(E0, W) -> file_close(E0).
'prim_feof'(E0, W) -> file_eof(E0).
'prim_fgetc'(E0, W) -> read_chr(E0).
'prim_fopen'(E0, E1, W) -> file_open(E0, E1).
'prim_fprint'(E0, E1, W) -> print_str(E0, E1).
'prim_fread'(E0, W) -> read_str(E0).
'prim_io_bind'(E0, E1, E2, E3) -> 'APPLY0'(E3, E2).
'prim_strIsNull'(E0, W) -> str_null(E0).
'runMain0'() -> 'EVAL0'('APPLY0'('Main_main'(), undefined)).
'run__IO'(E0, E1) -> 'APPLY0'(E1, undefined).
'world'(E0) -> E0.
bool_cast(true) -> ?TRUE;
bool_cast(_)    -> ?FALSE.

file_close(undefined) ->
    ?FALSE;
file_close(Handle) ->
    case file:close(Handle) of
        ok -> ?TRUE;
        _ -> ?FALSE
    end.

file_eof(undefined) ->
    ?FALSE;
file_eof(Handle) ->
    case file:read(Handle,1) of
        eof -> ?TRUE;
        {ok, _} -> case file:position(Handle, {cur, -1}) of
                       {ok, _} -> ?FALSE;
                       {error, _} -> ?TRUE
                   end;
        {error, _} -> ?TRUE
    end.

file_open(Name, Mode) ->
    ModeOpts = case Mode of
                   "r" ->  [read];
                   "w" ->  [write];
                   "r+" -> [read, write]
               end,
    case file:open(Name, ModeOpts) of
        {ok, Handle} -> Handle;
        _ -> undefined
    end.

main(_Args) ->
    runMain0().

print_str(undefined, _) ->
    ?FALSE;
print_str(Handle, Str) ->
    case file:write(Handle, Str) of
        ok -> ?TRUE;
        _ -> ?FALSE
    end.

read_chr(undefined) ->
    -1;
read_chr(Handle) ->
    case file:read(Handle, 1) of
        {ok, [Chr]} -> Chr;
        _ -> -1
    end.

read_str(undefined) ->
    "";
read_str(Handle) ->
    case file:read_line(Handle) of
        {ok, Data} -> Data;
        _ -> ""
    end.

str_null([]) ->
    ?TRUE;
str_null(_) ->
    ?FALSE.

