% Sets up PostgreSQL connection, on app start.
% TODO Setup supervision, retry connect if failure
-module(db).

-behaviour(gen_server).

-export([ start_link/0 ]).
-export([ connect/0, find_one/2 ]).
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

find_one(Collection, Query) ->
    QueryAsList = maps:fold(fun(K, V, Acc) -> [K,V|Acc] end, [], Query),
    QueryString = (
        get_first_part_of_query_string(Collection) ++
        get_rest_of_query_string(QueryAsList) ++
        get_string_part_for_limit_one()
    ),
    RawSQLData = gen_server:call({global, ?MODULE}, { QueryString }),
    DataAsMaps = turn_data_into_maps(RawSQLData),
    [ Item|_ ] = DataAsMaps,
    Item.

%%========================================================================
%%    Turns the standard odbc response
%%    into maps.
%%
%%    {selected,
%%     [ "id","email","password","modified" ],
%%     [ { 1, "adi@adi.com", "123456", null } ]
%%    }
%%  
%%    TURNED INTO:       
%%         
%%    [#{"email" => "adi@adi.com","id" => 1,"modified" => null, "password" => "123456"}]
%%    !!! Might be a bad idea to turn this data into maps
%%    ASK SOMEBODY WHO KNOWS STUFF
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
get_first_part_of_query_string(Collection) ->
    utils:interpolate_variables_in_string("SELECT * FROM ~s", [Collection]).

get_rest_of_query_string([H1, H2|T]) ->
  utils:interpolate_variables_in_string(" WHERE ~s = '~s'", [H1, H2]) ++ get_query_string_next_part(T).

get_query_string_next_part([]) ->
    "";
get_query_string_next_part([H1, H2]) ->
    utils:interpolate_variables_in_string(" AND ~s = '~s'", [H1,H2]);
get_query_string_next_part([H1, H2|T]) ->
    get_query_string_next_part([H1, H2]) ++ get_query_string_next_part(T).
get_string_part_for_limit_one() ->
    " limit 1".

%%========================================================================
%%                  Call back functions
%%========================================================================
start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

init(_Args) ->
    connect(toDatabase),
    State = [],
    {ok, State}.

% Does the actual call to the database
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

