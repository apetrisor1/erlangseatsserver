% Sets up mongo connection, on app start.
-module(db).

-export([
    binary_string_to_objectid/1,
    connect/0,
    connect/2,
    find/1,
    find/2,
    find_by_id/2,
    find_one/2,
    insert_one/2,
    object_id_to_list/1,
    objectid_to_binary_string/1,
    update_one/3
]).

% TODO Setup supervision, retry connect if failure
connect() ->
    connect(localhost, 27017).
connect(_Scheme, _Port) ->
    Database = <<"erlang">>,

    case mc_worker_api:connect ([{database, Database}]) of 
        {ok, Connection} ->
            io:format("MongoDB Connection is OK ~p ~n ~n", [Connection]),
            register(database, Connection),
            {ok, Connection};
        _ ->
            io:format("MongoDB Connection not established.. ~n ~n"),
            exit(1)
    end.

find(Collection) ->
    utils:log(),
    io:format("Getting all ~nfrom ~p, ~nusing process ~p ~n~n", [Collection, whereis(database)]),
    case mc_worker_api:find(whereis(database), Collection, #{}) of
        []             -> [];
        { ok, Cursor } -> mc_cursor:rest(Cursor)
    end.

find(Collection, Query) ->
    utils:log(),
    io:format("Querying ~p ~nfrom ~p, ~nusing process ~p ~n~n", [Query, Collection, whereis(database)]),
    case mc_worker_api:find(whereis(database), Collection, Query) of
        []             -> [];
        { ok, Cursor } -> mc_cursor:rest(Cursor)
    end.

find_by_id(Collection, Id) ->
    utils:log(),
    io:format("Searching for ID ~p ~nfrom ~p, ~nusing process ~p ~n~n", [Id, Collection, whereis(database)]),
    mc_worker_api:find_one(whereis(database), Collection, #{ <<"_id">> => Id }).
    
find_one(Collection, Query) ->
    utils:log(),
    io:format("Querying one ~p ~nfrom ~p, ~nusing process ~p ~n~n", [Query, Collection, whereis(database)]),
    mc_worker_api:find_one(whereis(database), Collection, Query).

insert_one(Collection, Object) ->
    utils:log(),
    io:format("Inserting one ~p ~ninto ~p, ~nusing process ~p ~n~n", [Object, Collection, whereis(database)]),
    mc_worker_api:insert(whereis(database), Collection, Object).

update_one(Collection, Id, Object) ->
    utils:log(),
    io:format("Updating ID ~p ~n with body ~p, ~n using process ~p ~n~n", [Id, Object, whereis(database)]),
    Command = #{ <<"$set">> => Object },
    mc_worker_api:update(whereis(database), Collection, #{ <<"_id">> => Id }, Command),
    mc_worker_api:find_one(whereis(database), Collection, #{ <<"_id">> => Id }).

% AUX - MONGO DB OBJECT ID FORMAT
% https://stackoverflow.com/questions/10383395/how-to-convert-objectid-to-binary-subtype-3-uuid-with-mongodb-erlang-and-bson

%%This method is used to generate ObjectId from binary string.
binary_string_to_objectid(BinaryString) ->
    binary_string_to_objectid(BinaryString, []).

binary_string_to_objectid(<<>>, Result) ->
    {list_to_binary(lists:reverse(Result))};
binary_string_to_objectid(<<BS:2/binary, Bin/binary>>, Result) ->
    binary_string_to_objectid(Bin, [erlang:binary_to_integer(BS, 16)|Result]).

%%This method is used to generate a list from the above generated ObjectID.
object_id_to_list(Id) ->
    { Id1 } = binary_string_to_objectid(Id),
    binary_to_list(Id1).

%%This method is used to generate binary string from objectid.
objectid_to_binary_string({Id}) ->
    objectid_to_binary_string(Id, []).

objectid_to_binary_string(<<>>, Result) ->
    list_to_binary(lists:reverse(Result));
objectid_to_binary_string(<<Hex:8, Bin/binary>>, Result) ->
    StringList1 = erlang:integer_to_list(Hex, 16),
    StringList2 = case erlang:length(StringList1) of
        1 ->
            ["0"|StringList1];
        _ ->
            StringList1
    end,
    objectid_to_binary_string(Bin, [StringList2|Result]).

