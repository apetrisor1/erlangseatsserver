% Sets up PostgreSQL connection, on app start.
% TODO Setup supervision, retry connect if failure
-module(db).

-behaviour(gen_server).

-export([ start_link/0, connect/0 ]).
-export([ find/1, find/2, find_one/2, insert_one/2 ]).
-export([ init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2 ]).

%%========================================================================
%%                  Client calls
%%========================================================================
connect() ->
    start_link().
connect(toDatabase) ->
    odbc:start(),
    attempt(odbc:connect(get_connection_string(),[])).

attempt({ ok, Connection }) ->
    io:format("PostgreSQL Connection is OK ~p ~n ~n", [Connection]),
    register(database, Connection),
    { ok, Connection };
attempt(_) ->
    io:format("PostgreSQL Connection not established.. ~n ~n"),
    exit(1).

get_db_related_env_vars() ->
    { ok, DSN }              = application:get_env(seats_server, dataSourceName),
    { ok, PostgresUser }     = application:get_env(seats_server, postgresUser),
    { ok, PostgresPassword } = application:get_env(seats_server, postgresPassword),
    [ DSN, PostgresUser, PostgresPassword ].

get_connection_string() ->
    utils:interpolate_variables_in_string(
        "DSN=~s;UID=~s;PWD=~s", 
        get_db_related_env_vars()
    ).

insert_one(Collection, Map) ->
    QueryString = (
        first_part_of_INSERT_string(Collection) ++
        last_part_of_INSERT_string(Map)
    ),
    gen_server:call({global, ?MODULE}, { QueryString }),
    find_one(Collection, Map).

find(Collection) ->
    QueryString = first_part_of_SELECT_string(Collection),
    RawSQLData = gen_server:call({global, ?MODULE}, { QueryString }),
    DataAsMaps = turn_data_into_maps(RawSQLData),
    DataAsMaps.

find(Collection, Query) ->
    QueryAsList = maps:fold(fun(K, V, Acc) -> [K,V|Acc] end, [], Query),
    QueryString = (
        first_part_of_SELECT_string(Collection) ++
        last_part_of_SELECT_string(QueryAsList)
    ),
    RawSQLData = gen_server:call({global, ?MODULE}, { QueryString }),
    DataAsMaps = turn_data_into_maps(RawSQLData),
    DataAsMaps.

find_one(Collection, Query) ->
    QueryAsList = maps:fold(fun(K, V, Acc) -> [K,V|Acc] end, [], Query),
    QueryString = (
        first_part_of_SELECT_string(Collection) ++
        last_part_of_SELECT_string(QueryAsList) ++
        limit_one_SELECT_string()
    ),
    RawSQLData = gen_server:call({global, ?MODULE}, { QueryString }),
    DataAsMaps = turn_data_into_maps(RawSQLData),
    utils:shift(DataAsMaps).

%%========================================================================
%%                  Call back functions
%%========================================================================
start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

init(_Args) ->
    process_flag(trap_exit, true),
    connect(toDatabase),
    State = [],
    {ok, State}.

% Calls DB
handle_call(Request, _From, State) ->
    Data = case Request of
        { SQLParamedQuery, SQLQueryParams } ->
            odbc:param_query(whereis(database), SQLParamedQuery, SQLQueryParams);
        { SQLQuery } ->
            odbc:sql_query(whereis(database), SQLQuery)
    end,
    {reply, Data, State}.

handle_cast(Request, State) ->
    io:format("handle cast request: ~p~n", [Request]),
    {noreply, State}.

handle_info(Info, State) ->
    io:format("handle_info request: ~p~n", [Info]),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

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
%%          Functions to manipulate the DB query string
%%========================================================================
%%                               SELECT
%%========================================================================
first_part_of_SELECT_string(Collection) ->
    utils:interpolate_variables_in_string("SELECT * FROM ~s", [Collection]).

next_part_of_SELECT_string([]) ->
    "";
next_part_of_SELECT_string([H1, H2]) ->
    utils:interpolate_variables_in_string(" AND ~s = '~s'", [H1,H2]);
next_part_of_SELECT_string([H1, H2|T]) ->
    next_part_of_SELECT_string([H1, H2]) ++ next_part_of_SELECT_string(T).

last_part_of_SELECT_string([H1, H2|T]) ->
  utils:interpolate_variables_in_string(" WHERE ~s = '~s'", [H1, H2]) ++ next_part_of_SELECT_string(T).

limit_one_SELECT_string() ->
    " limit 1".

%%========================================================================
%%                               INSERT
%%========================================================================
first_part_of_INSERT_string(Collection) ->
    utils:interpolate_variables_in_string("INSERT INTO ~s ", [Collection]).

last_part_of_INSERT_string(Map) ->
    Keys0 = maps:fold(utils:get_keys_as_csv(), "", Map),
    Keys1 = "(" ++ Keys0 ++ ")",
    Values0 = maps:fold(utils:get_values_as_csv(), "", Map),
    Values1 = " VALUES (" ++ Values0 ++ ");",
    % Remove last comma in query string before returning it.
    lists:reverse(lists:delete($,,lists:reverse(Keys1))) ++
    lists:reverse(lists:delete($,,lists:reverse(Values1))).
