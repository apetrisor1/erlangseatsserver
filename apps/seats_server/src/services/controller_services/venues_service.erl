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
    { SeatCoords, BodyWithoutSeatCoords } = maps:take(<<"seat_coords">>, Body),
    
    Venue = db:insert_one_map(<<"venues">>, BodyWithoutSeatCoords ),
    Seats = seats_service:create_multiple_seats(Venue, SeatCoords),

    maps:put("seats", {seats, Seats}, Venue).

find() ->
    db:find(<<"venues">>).

find(Query) ->
    db:find(<<"venues">>, Query).

find_by_id(Id) ->
    db:find_one(<<"venues">>, #{ id => Id }).

find_one(Query) ->
    db:find_one(<<"venues">>, Query).

% BROKEN - MISSING DB HANDLER
update_one(Id, Body) ->
    db:update_one(<<"venues">>, Id, Body).

view(Venues) when is_list(Venues) ->
    lists:map(fun(Venue) -> view(Venue) end, Venues);
view(Venue0) ->
    Venue1 = utils:create_map_with_binary_keys_and_values(Venue0),
    maps:without([], Venue1).
