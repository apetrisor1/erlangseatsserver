-module(venue).
-export([
  init/2,
  allowed_methods/2,
  content_types_accepted/2,
  content_types_provided/2,
  router/2
]).

% Generic
init(Req0, State) ->
	{ cowboy_rest, Req0, State }.

allowed_methods(Req0, State) ->
	{ [<<"PUT">>, <<"GET">>], Req0, State }.

content_types_accepted(Req0, State) ->
    { [ { { <<"application">>, <<"json">>, [] }, router } ], Req0, State }.

content_types_provided(Req0, State) ->
	{ [ { { <<"application">>, <<"json">>, [] }, router } ], Req0, State }.

router(Req0, State) ->
    Bindings     = maps:get(bindings, Req0),
    VenueId      = maps:get(venueId, Bindings, notProvided),

    router(
        cowboy_req:method(Req0),
        VenueId,
        Req0,
        State
    ).

router(<<"PUT">>, VenueId, Req0, State) ->
    { stop, put_venue(VenueId, Req0), State };
router(<<"GET">>, VenueId, Req0, State) ->
    { stop, get_venue(VenueId, Req0), State }.

put_venue(VenueId, Req0) ->
    { ok, RequestBody, _ } = utils:read_body(Req0),
    Body  = jiffy:decode(RequestBody, [return_maps]),
    Venue = venues_service:update_one(VenueId, Body),

    cowboy_req:reply(
        200,
        #{ <<"content-type">> => <<"application/json">> },
        jiffy:encode(venues_service:view(Venue)),
        Req0
    ).

get_venue(VenueId, Req0) ->
    Venue = venues_service:find_by_id(VenueId),
    VenueWithSeats = venues_service:populate(Venue, seats),

    cowboy_req:reply(
        200,
        #{ <<"content-type">> => <<"application/json">> },
        jiffy:encode(venues_service:view(VenueWithSeats)),
        Req0
    ).
