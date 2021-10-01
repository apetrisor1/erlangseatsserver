-module(seats_service).

-export([
    create_multiple_seats/2,
    delete_seats/1,
    update_multiple_seats/2,
    find/1,
    view/1
]).

create_multiple_seats(Venue, SeatCoords) ->
    VenueId = integer_to_binary(maps:get("id", Venue)),
    create_seats_for_this_venue(SeatCoords, VenueId).

delete_seats(Query) ->
    db:delete_many(<<"seats">>, Query).

update_multiple_seats(Venue, SeatCoords) ->
    VenueId = integer_to_binary(maps:get("id", Venue)),
    delete_seats(#{ venue_id => VenueId }),
    create_seats_for_this_venue(SeatCoords, VenueId).

find(Query) ->
    db:find(<<"seats">>, Query).

view(Seats) when is_list(Seats) ->
    lists:map(fun(Seat) -> view(Seat) end, Seats);
view(Seat0) ->
    Seat1 = utils:create_map_with_binary_keys_and_values(Seat0),
    maps:without([], Seat1).

create_seats_for_this_venue(SeatCoords, VenueId) ->
     db:insert_sql_like_list(
        <<"seats">>,
        [<<"lon">>, <<"lat">>, <<"venue_id">>],
        lists:map(fun(Coord) ->
            lists:concat([Coord, [VenueId]])
        end, SeatCoords)
    ).