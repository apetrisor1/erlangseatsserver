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
    { _, User }  = db:insert_one(
        <<"users">>,
        maps:put(<<"password">>, Hash, UserWithoutPass)
    ),
    User.

find_by_id(Id) ->
    db:find_by_id(<<"users">>, Id).

find_one(Query) ->
    db:find_one(<<"users">>, Query).

get_jwt(User) ->
    { _, { Id } } = maps:find(<<"_id">>, User),
    jwerl:sign([{ id, binary_to_list(Id) }], hs256, <<"secretKey">>).

view(User) ->
    maps:without([<<"_id">>, <<"password">>], User).
