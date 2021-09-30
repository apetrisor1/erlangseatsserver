-module(db_utils).

-export([
    turn_data_into_maps/1,
    first_part_of_SELECT/1,
    last_part_of_SELECT/1,
    limit_one_SELECT/0,
    first_part_of_INSERT/1,
    last_part_of_INSERT_MAP/1,
    last_part_of_INSERT_LIST/2,
    last_part_RETURNING_ALL/0
]).

%%========================================================================
%%      Turns the odbc response data tuple into maps.
%%      Example:
%%
%%from: {selected,
%%        [ "id","email","password","modified" ],
%%        [ { 1, "adi@adi.com", "123456", null } ]
%%       }
%%
%%to:   [#{"email" => "adi@adi.com","id" => 1,"modified" => null, "password" => "123456"}]
%%
%%      Is it a good idea to turn this data into maps early on?
%%========================================================================
turn_data_into_maps({ selected, Keys, TuplesWithValues }) ->
  maps_from_keys_and_tuples(Keys, TuplesWithValues, []).

maps_from_keys_and_tuples(_Keys, [], Acc0) ->
  Acc0;
maps_from_keys_and_tuples(Keys, [H|T], Acc0) ->
  Acc1 = map_from_keys_and_tuple(Keys, H, #{}, 1),
  maps_from_keys_and_tuples(Keys, T, [Acc1|Acc0]).

map_from_keys_and_tuple([], _Tuple, Acc0, _Counter) ->
  Acc0;
map_from_keys_and_tuple([H|T], Tuple, Acc0, Counter) ->
  Value = element(Counter, Tuple),
  Acc1 = maps:put(H, Value, Acc0),
  map_from_keys_and_tuple(T, Tuple, Acc1, Counter + 1).



%%========================================================================
%%                Functions to create DB query strings
%%========================================================================
%%                               SELECT
%%========================================================================
first_part_of_SELECT(Collection) ->
    utils:interpolate_variables_in_string("SELECT * FROM ~s", [Collection]).

next_part_of_SELECT_string([]) ->
    "";
next_part_of_SELECT_string([H1, H2]) ->
    utils:interpolate_variables_in_string(" AND ~s = '~s'", [utils:to_string(H1), utils:to_string(H2)]);
next_part_of_SELECT_string([H1, H2|T]) ->
    next_part_of_SELECT_string([H1, H2]) ++ next_part_of_SELECT_string(T).

last_part_of_SELECT([H1, H2|T]) ->
  utils:interpolate_variables_in_string(" WHERE ~s = '~s'", [utils:to_string(H1), utils:to_string(H2)]) ++ next_part_of_SELECT_string(T).

limit_one_SELECT() ->
    " limit 1".

%%========================================================================
%%                               INSERT
%%========================================================================
first_part_of_INSERT(Collection) ->
    utils:interpolate_variables_in_string("INSERT INTO ~s ", [Collection]).

last_part_of_INSERT_MAP(Map) ->
    Keys0 = maps:fold(utils:get_keys_as_csv(), "", Map),
    Keys1 = "(" ++ Keys0 ++ ")",

    Values0 = maps:fold(utils:get_values_as_csv(), "", Map),
    Values1 = " VALUES (" ++ Values0 ++ ")",

    utils:remove_trailing_coma(Keys1) ++
    utils:remove_trailing_coma(Values1).

last_part_of_INSERT_LIST(ColumnNamesList, RowsMatrix) ->
    Keys = lists:foldl(utils:get_list_as_csv(), "" , ColumnNamesList),
    ColumnNamesQueryString = "(" ++ Keys ++ ")",

    RowsList = lists:map(fun(Item0) ->  
        Item1 = lists:foldl(utils:get_list_as_csv(), "" , Item0),
        utils:remove_trailing_coma(Item1)
    end, RowsMatrix),

    RowsQueryString = " VALUES " ++ lists:foldl(fun(Coord, Acc) ->  
        Acc ++ "(" ++ Coord ++ ")" ++ ","
    end, "", RowsList),

    utils:remove_trailing_coma(ColumnNamesQueryString) ++
    utils:remove_trailing_coma(RowsQueryString).

%%========================================================================
%%                               RETURNING
%%========================================================================
last_part_RETURNING_ALL() ->
    " RETURNING *".