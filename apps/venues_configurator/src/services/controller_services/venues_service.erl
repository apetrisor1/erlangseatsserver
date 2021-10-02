-module(venues_service).
-export([
    create/1,
    find/0,
    find/1,
    find_by_id/1,
    find_one/1,
    update_by_id/2,
    populate/2,
    view/1
]).

create(Body) ->
    % TODO: Validate.
    % Set up a venue model that exports its' name, so we may use it as collection name.
    { SeatCoords, BodyWithoutSeatCoords } = maps:take(<<"seats">>, Body),

    utils:log(seatcoords, SeatCoords),
    
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

update_by_id(Id, Body) ->
    { SeatCoords, BodyWithoutSeatCoords } = maps:take(<<"seats">>, Body),

    case venues_service:find_by_id(Id) of
        [] ->
            '404';
        Venue ->
            Seats = seats_service:update_multiple_seats(Venue, SeatCoords),
            Venue1 = db:update_by_id(<<"venues">>, Id, BodyWithoutSeatCoords),
            maps:put("seats", {seats, Seats}, Venue1)
    end.
    
populate([], seats) ->
    [];
populate([H|T], seats) ->
    [populate(H, seats)] ++ populate(T, seats);
populate(Venue, seats) -> 
    VenueId = maps:get("id", Venue),
    Seats = seats_service:find(#{ venue_id => VenueId }),
    maps:put("seats", {seats, Seats}, Venue).

view(Venues) when is_list(Venues) ->
    lists:map(fun(Venue) -> view(Venue) end, Venues);
view(Venue0) ->
    Venue1 = utils:create_map_with_binary_keys_and_values(Venue0),
    maps:without([], Venue1).
