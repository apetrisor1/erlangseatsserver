-module(venues_service).
-export([
    create/1,
    find/0,
    find/1,
    find_by_id/1,
    find_one/1,
    update_one/2,
    view/1
]).

create(Body) ->
    % TODO: Validate.
    % Set up a venue model that exports its' name, so we may use it as collection name.
    { _, Venue }  = db:insert_one(
        <<"venues">>,
        Body
    ),
    Venue.

find() ->
    db:find(<<"venues">>).

find(Query) ->
    db:find(<<"venues">>, Query).

find_by_id(Id) ->
    db:find_by_id(<<"venues">>, Id).

find_one(Query) ->
    db:find_one(<<"venues">>, Query).

update_one(Id, Body) ->
    db:update_one(<<"venues">>, Id, Body).

view(Venues) when is_list(Venues) ->
    lists:map(fun(Venue) -> view(Venue) end, Venues);
view(Venue) ->
    maps:without([<<"_id">>, <<"owner">>], Venue).
