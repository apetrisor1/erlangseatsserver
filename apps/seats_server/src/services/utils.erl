-module(utils).

-export([
    create_map_with_potentially_binary_keys_and_values/1,
    compare_passwords/2,
    interpolate_variables_in_string/2,
    read_body/1  
]).

compare_passwords(P1, P2) ->
    { ok, P2 } =:= bcrypt:hashpw(P1, P2).

interpolate_variables_in_string(String, Variables) when is_list(Variables) ->
    lists:flatten( io_lib:format(String, Variables) ).

% Cowboy specific
read_body(Req0) -> read_body(Req0, <<>>).
read_body(Req0, Acc) ->
    case cowboy_req:read_body(Req0) of
        {ok, Data, Req} -> {ok, << Acc/binary, Data/binary >>, Req};
        {more, Data, Req} -> read_body(Req, << Acc/binary, Data/binary >>)
    end.

%%========================================================================
%%    Copy a map and:
%%    - format all keys as binary strings. 
%%    - format all Erlang string values into binary strings. 
%%    
%%    #{"email" => "adi@adi.com","id" => 5,"modified" => null,"password" => "123456"}
%%    ==>
%%    #{<<"email">> => <<"adi@adi.com">>,<<"id">> => 5, <<"modified">> => null,<<"password">> => <<"123456">>}
%%========================================================================
create_map_with_potentially_binary_keys_and_values(Map0) ->
    maps:fold(
        fun(K, V, Acc) ->
            create_map_with_potentially_binary_keys_and_values(K, V, Acc)
        end,
        #{},
        Map0
    ).

create_map_with_potentially_binary_keys_and_values(K0, V0, Acc0) ->
  K1 = maybe_turn_list_to_binary(K0),
  V1 = maybe_turn_list_to_binary(V0),
  maps:put(K1, V1, Acc0).

maybe_turn_list_to_binary(V) when is_list(V) ->
    list_to_binary(V);
maybe_turn_list_to_binary(V) ->
    V.