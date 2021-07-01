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

    { SeatCoords, BodyWithoutSeatCoords } = maps:take(<<"seatCoords">>, Body),

    % 2. Create seats
    % db:insert_sql_like_list(
    %     <<"coordinates">>,
    %     [ <<"lon">>, <<"lat">> ],
    %     SeatCoords
    % ),

    % 1. Insert venue
    io:format("1 BodyWithoutSeatCoords ~p~n", [BodyWithoutSeatCoords]),
    { _, Venue }  = db:insert_one_map(
        <<"venues">>,
        BodyWithoutSeatCoords
    ),
    io:format("Venue ~p~n", [Venue]),
    ok.

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
