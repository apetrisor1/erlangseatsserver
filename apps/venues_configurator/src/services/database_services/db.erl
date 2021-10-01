% Sets up PostgreSQL connection, on app start.
% TODO Setup supervision, retry connect if failure
-module(db).

-behaviour(gen_server).

-export([ start_link/0, connect/0 ]).
-export([
    delete_one/2,
    delete_many/2,
    find/1,
    find/2,
    find_one/2,
    insert_one_map/2,
    insert_sql_like_list/3,
    update_by_id/3
]).
-export([ init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2 ]).

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
    { ok, DSN }              = application:get_env(venues_configurator, dataSourceName),
    { ok, PostgresUser }     = application:get_env(venues_configurator, postgresUser),
    { ok, PostgresPassword } = application:get_env(venues_configurator, postgresPassword),
    [ DSN, PostgresUser, PostgresPassword ].

get_connection_string() ->
    utils:interpolate_variables_in_string(
        "DSN=~s;UID=~s;PWD=~s;", 
        get_db_related_env_vars()
    ).

%%========================================================================
%%                            Client calls
%%========================================================================
%%========================================================================
%%                               DELETE
%%========================================================================
delete_one(Collection, Id) -> % not yet tested
    QueryString = (
        db_utils:first_part_of_DELETE(Collection) ++
        db_utils:next_part_of_DELETE("id", "=") ++
        if is_number(Id) ->
            integer_to_list(Id);
        true ->
            Id
        end
    ),
    gen_server:call({global, ?MODULE}, { QueryString }).

delete_many(Collection, Query) ->
    QueryAsList = maps:fold(fun(K, V, Acc) -> [K,V|Acc] end, [], Query),

    QueryString = (
        db_utils:first_part_of_DELETE(Collection) ++
        db_utils:last_part_of_SELECT(QueryAsList)
    ),
    gen_server:call({global, ?MODULE}, { QueryString }).

%%========================================================================
%%                               INSERT
%%========================================================================
insert_one_map(Collection, Map) ->
    QueryString = (
        db_utils:first_part_of_INSERT(Collection) ++
        db_utils:last_part_of_INSERT_MAP(Map) ++
        db_utils:last_part_RETURNING_ALL()
    ),
    RawSQLData = gen_server:call({global, ?MODULE}, { QueryString }),
    [DataAsMaps] = db_utils:turn_data_into_maps(RawSQLData),
    DataAsMaps.

update_by_id(Collection, Id, Map) ->
    MapAsList = maps:fold(fun(K, V, Acc) -> [K,V|Acc] end, [], Map),

    QueryString = (
        db_utils:first_part_of_UPDATE(Collection) ++
        db_utils:next_part_of_UPDATE(MapAsList) ++
        db_utils:last_part_of_SELECT(["id", Id]) ++
        db_utils:last_part_RETURNING_ALL()
    ),

    RawSQLData = gen_server:call({global, ?MODULE}, { QueryString }),
    [DataAsMaps] = db_utils:turn_data_into_maps(RawSQLData),
    utils:log(rwa, DataAsMaps),
    Map.

insert_sql_like_list(Collection, ColumnNamesList, RowsMatrix) ->
    QueryString = (
        db_utils:first_part_of_INSERT(Collection) ++
        db_utils:last_part_of_INSERT_LIST(ColumnNamesList, RowsMatrix) ++
        db_utils:last_part_RETURNING_ALL()
    ),
    RawSQLData = gen_server:call({global, ?MODULE}, { QueryString }),
    DataAsMaps = db_utils:turn_data_into_maps(RawSQLData),
    DataAsMaps.

%%========================================================================
%%                               SELECT
%%========================================================================
find(Collection) ->
    QueryString = db_utils:first_part_of_SELECT(Collection),
    RawSQLData = gen_server:call({global, ?MODULE}, { QueryString }),
    DataAsMaps = db_utils:turn_data_into_maps(RawSQLData),
    DataAsMaps.

find(Collection, Query) ->
    QueryAsList = maps:fold(fun(K, V, Acc) -> [K,V|Acc] end, [], Query),
    QueryString = (
        db_utils:first_part_of_SELECT(Collection) ++
        db_utils:last_part_of_SELECT(QueryAsList)
    ),
    RawSQLData = gen_server:call({global, ?MODULE}, { QueryString }),
    DataAsMaps = db_utils:turn_data_into_maps(RawSQLData),
    DataAsMaps.

find_one(Collection, Query) ->
    QueryAsList = maps:fold(fun(K, V, Acc) -> [K,V|Acc] end, [], Query),
    QueryString = (
        db_utils:first_part_of_SELECT(Collection) ++
        db_utils:last_part_of_SELECT(QueryAsList) ++
        db_utils:limit_one_SELECT()
    ),
    RawSQLData = gen_server:call({global, ?MODULE}, { QueryString }),
    DataAsMaps = db_utils:turn_data_into_maps(RawSQLData),
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
handle_call(Request, { From, _ }, State) ->
    Data = case Request of
        { SQLParamedQuery, SQLQueryParams } ->
            odbc:param_query(whereis(database), SQLParamedQuery, SQLQueryParams);
        { SQLQuery } ->
            io:format("~nDB Call from: ~p~n", [From]),
            io:format("Query: ~p~n", [SQLQuery]),
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