-module(utils).

-export([
    create_map_with_binary_keys_and_values/1,
    compare_passwords/2,
    get_keys_as_csv/0,
    get_list_as_csv/0,
    get_values_as_csv/0,
    interpolate_variables_in_string/2,
    is_numeric/1,
    log/1,
    log/2,
    log_one_line/2,
    read_body/1,
    remove_trailing_coma/1,
    shift/1,
    to_string/1
]).

%%========================================================================
%%    Copy a map and:
%%    - format all keys as binary strings. 
%%    - format all values of type string (Erlang list) into binary strings. 
%%    
%%    #{"email" => "adi@adi.com","id" => 5,"modified" => null,"password" => "123456"}
%%    ==>
%%    #{<<"email">> => <<"adi@adi.com">>,<<"id">> => 5, <<"modified">> => null,<<"password">> => <<"123456">>}
%%========================================================================
create_map_with_binary_keys_and_values(Map0) ->
    maps:fold(
        fun(K, V, Acc) ->
            replace_lists_with_binaries(K, V, Acc)
        end,
        #{},
        Map0
    ).

replace_lists_with_binaries(K0, V0, Acc0) ->
    K1 = maybe_list_to_binary(K0),
    V1 = maybe_list_to_binary(V0),
    maps:put(K1, V1, Acc0).

% Populated views
maybe_list_to_binary({seats, V}) ->
    seats_service:view(V);
% Regular views
maybe_list_to_binary(V) when is_list(V) ->
    list_to_binary(V);
maybe_list_to_binary(V) ->
    V.

compare_passwords(P1, P2) ->
    { ok, P2 } =:= bcrypt:hashpw(P1, P2).

get_keys_as_csv() ->
    fun
        (Key, _Value, Acc) when is_binary(Key)->
            Acc ++ binary_to_list(Key) ++ ",";
        (Key, _Value, Acc) ->
            Acc ++ Key ++ ","
    end.

get_list_as_csv() ->
    fun
        (Value, Acc) when is_binary(Value)->
            Acc ++ binary_to_list(Value) ++ ",";
        (Value, Acc) ->
            Acc ++ Value ++ ","
    end.

is_numeric(L) ->
    Float = (catch erlang:list_to_float(L)),
    Int = (catch erlang:list_to_integer(L)),
    is_number(Float) orelse is_number(Int).

get_values_as_csv() ->
    fun
        (_Key, Value, Acc) when is_binary(Value)->
            Acc ++ "'" ++ binary_to_list(Value) ++ "'" ++ ",";
        (_Key, Value, Acc) ->
            Acc ++ "'" ++ Value ++ "'" ++ ","
    end.

interpolate_variables_in_string(String, Variables) when is_list(Variables) ->
    lists:flatten( io_lib:format(String, Variables) ).

log(Stuff) ->
    io:format("~nLogged~n~p~n", [Stuff]).

log(Text, Stuff) ->
    io:format("~n~p~n~p~n", [Text, Stuff]).

log_one_line(Text, Stuff) ->
    io:format("~n~p~p~n", [Text, Stuff]).

% Cowboy specific
read_body(Req0) -> read_body(Req0, <<>>).
read_body(Req0, Acc) ->
    case cowboy_req:read_body(Req0) of
        {ok, Data, Req}   -> {ok, << Acc/binary, Data/binary >>, Req};
        {more, Data, Req} -> read_body(Req, << Acc/binary, Data/binary >>)
    end.

remove_trailing_coma(List) ->
    lists:reverse(lists:delete($,,lists:reverse(List))).

shift([H|_]) ->
    H;
shift([]) ->
    [].

to_string(A) when is_number(A) ->
    integer_to_list(A);
to_string(A) -> A.