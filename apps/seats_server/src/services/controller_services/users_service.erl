-module(users_service).
% This service gets called from the user and auth controllers.
% When creating/updating a user, service:
% - validates user input
% - assigns defaults
% - calls db service with the body to be added.
-export([
    create/1,
    find_by_id/1,
    find_one/1,
    get_jwt/1,
    view/1
]).

create(UserBody) ->
    % TODO: Validate.
    % Set up a user model that exports its' name, so we may use it as collection name.
    { Password, UserWithoutPass } = maps:take(<<"password">>, UserBody),
    { ok, Salt } = bcrypt:gen_salt(),
    { ok, Hash } = bcrypt:hashpw(Password, Salt),
    db:insert_one(
        <<"users">>,
        maps:put(<<"password">>, list_to_binary(Hash), UserWithoutPass)
    ).

find_by_id(Id) ->
    db:find_by_id(<<"users">>, Id).

find_one(Query) ->
    db:find_one(<<"users">>, Query).

get_jwt(User) ->
    { _, SecretKey } = application:get_env(seats_server, secretKey),
    { _, Id }        = maps:find("id", User),
    jwerl:sign([{ id, Id }], hs256, SecretKey).

view(User0) ->
    User1 = utils:create_map_with_binary_keys_and_values(User0),
    maps:without(["id", "password"], User1).
