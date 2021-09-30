-module(user).
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
	% { [<<"PUT">>, <<"GET">>], Req0, State }.
	{ [<<"GET">>], Req0, State }.

content_types_accepted(Req0, State) ->
    { [ { { <<"application">>, <<"json">>, [] }, router } ], Req0, State }.

content_types_provided(Req0, State) ->
	{ [ { { <<"application">>, <<"json">>, [] }, router } ], Req0, State }.

router(Req0, State) ->
    Bindings = maps:get(bindings, Req0),
    BindingsId = maps:get(userId, Bindings, notProvided),

    router(
        cowboy_req:method(Req0),
        get_id_from_bindings(BindingsId, Req0),
        Req0,
        State
    ).

% router(<<"PUT">>, UserId, Req0, State) ->
%     { stop, put_venue(UserId, Req0), State };
router(<<"GET">>, UserId, Req0, State) ->
    { stop, get_user(UserId, Req0), State }.

get_user(UserId, Req0) ->
    User = users_service:find_by_id(UserId),

    if is_map(User) ->
        cowboy_req:reply(
            200,
            #{ <<"content-type">> => <<"application/json">> },
            jiffy:encode(users_service:view(User)),
            Req0
        );
    true ->
        error_responses:respond_404(Req0)
    end.

get_id_from_bindings(<<"me">>, Req0) ->
    maps:get(id, maps:get(thisUser, Req0));
get_id_from_bindings(UserId, _) ->
    UserId.