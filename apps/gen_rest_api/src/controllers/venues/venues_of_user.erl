-module(venues_of_user).
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
	{ [<<"GET">>], Req0, State }.

content_types_accepted(Req0, State) ->
    { [ { { <<"application">>, <<"json">>, [] }, router } ], Req0, State }.

content_types_provided(Req0, State) ->
	{ [ { { <<"application">>, <<"json">>, [] }, router } ], Req0, State }.

router(Req0, State) ->
    utils:log(),
    router(
        cowboy_req:method(Req0),
        Req0,
        State
    ).

router(<<"GET">>, Req0, State) ->
    % TODO : Throw err if ID = notProvided
    Bindings     = maps:get(bindings, Req0),
    BindingsId   = maps:get(userId, Bindings, notProvided),
    UserId       = get_id_from_bindings(BindingsId, Req0),

    VenuesAsJson = jiffy:encode(
        venues_service:view(
            venues_service:find(#{ owner => UserId })
        )
    ),

    { stop, cowboy_req:reply(
        200,
        #{ <<"content-type">> => <<"application/json">> },
        VenuesAsJson,
        Req0
    ), State }.

get_id_from_bindings(<<"me">>, Req0) ->
    maps:get(id, maps:get(thisUser, Req0));
get_id_from_bindings(UserId, _) ->
    db:object_id_to_list(UserId).
