-module(venues).
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
	{ [<<"POST">>, <<"GET">>], Req0, State }.

content_types_accepted(Req0, State) ->
    { [ { { <<"application">>, <<"json">>, [] }, router } ], Req0, State }.

content_types_provided(Req0, State) ->
	{ [ { { <<"application">>, <<"json">>, [] }, router } ], Req0, State }.

router(Req0, State) ->
    router(
        cowboy_req:method(Req0),
        Req0,
        State
    ).

router(<<"POST">>, Req0, State) ->
    { stop, post_venue(Req0), State };
router(<<"GET">>, Req0, State) ->
    { stop, get_venues(Req0), State }.

post_venue(Req0) ->
    { ok, RequestBody, _ } = utils:read_body(Req0),
    Body = jiffy:decode(RequestBody, [return_maps]),
    Owner = maps:get(id, maps:get(thisUser, Req0)),
    io:format("Owner ~n~p", [Owner]),
    io:format("Owner ~n~p", [Owner]),
    io:format("Owner ~n~p", [Owner]),
    BodyWithOwner = maps:put(
        <<"owner_id">>,
        maps:get(id, maps:get(thisUser, Req0)),
        Body
    ),
    Venue = venues_service:create(BodyWithOwner),
    io:format("8 Venue ~p ~n", [Venue]),

    ok.
    % cowboy_req:reply(
    %     200,
    %     #{ <<"content-type">> => <<"application/json">> },
    %     jiffy:encode(venues_service:view(Venue)),
    %     Req0
    % ).

get_venues(Req0) ->
    Venues = venues_service:find(),
    cowboy_req:reply(
        200,
        #{ <<"content-type">> => <<"application/json">> },
        jiffy:encode(venues_service:view(Venues)),
        Req0
    ).
