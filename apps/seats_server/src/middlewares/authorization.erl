-module(authorization).
-behaviour(cowboy_middleware).

-export([execute/2]).

getMasterKeyProtectedRoutes() ->
    [<<"/auth/sign-in">>,
    <<"/auth/sign-up">>].

execute(Req0, State) ->
    #{ path := Path } = Req0,
    select_strategy(
        'isMasterKeyProtected?',
        lists:member(Path, getMasterKeyProtectedRoutes()),
        Req0,
        State
    ).

select_strategy('isMasterKeyProtected?', true, Req0, State) ->
    master_key(Req0, State);
select_strategy('isMasterKeyProtected?', false, Req0, State) ->
    jwt(Req0, State).

master_key(Req0, State) ->
    { bearer, Token } = cowboy_req:parse_header(<<"authorization">>, Req0),
    { ok, MasterKey } = application:get_env(seats_server, masterKey),
    authenticate_master_key(Token =:= MasterKey, Req0, State).

jwt(Req0, State) ->
    jwt(cowboy_req:parse_header(<<"authorization">>, Req0), Req0, State).

jwt({ bearer, Token }, Req0, State) ->
    { ok, SecretKey } = application:get_env(seats_server, secretKey),
    Content = jwerl:verify(Token, hs256, SecretKey),
    authenticate_jwt(Content, Req0, State);
jwt(_, Req0, _State) ->
    Req = cowboy_req:reply(401, Req0),
    { stop, Req }.

authenticate_master_key(true, Req0, State) ->
    { ok, Req0, State };
authenticate_master_key(false, Req0, _) ->
    Req = cowboy_req:reply(401, Req0),
    { stop, Req }.

authenticate_jwt({ ok, User }, Req0, State) ->
    UserWithStringId = maps:put(id, integer_to_list(maps:get(id, User)), User),
    { ok, maps:put(thisUser, UserWithStringId, Req0), State };
authenticate_jwt(_, Req0, _) ->
    Req1 = cowboy_req:reply(401, Req0),
    { stop, Req1 }.
