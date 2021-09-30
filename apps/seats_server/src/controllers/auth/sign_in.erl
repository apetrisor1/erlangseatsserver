-module(sign_in).

-export([init/2]).
-export([allowed_methods/2]).
-export([content_types_accepted/2]).
-export([content_types_provided/2]).
-export([sign_in/2]).

init(Req0, Opts) ->
	{ cowboy_rest, Req0, Opts }.

allowed_methods(Req0, State) ->
	{ [<<"POST">>], Req0, State }.

content_types_accepted(Req0, State) ->
    {[
        {{ <<"application">>, <<"json">>, [] }, sign_in }
    ], Req0, State}.

content_types_provided(Req0, State) ->
	{[
		{{ <<"application">>, <<"json">>, [] }, sign_in }
	], Req0, State}.

sign_in(Req0, State) ->
    { ok, RequestBody, _ } = utils:read_body(Req0),
    sign_in(RequestBody, Req0, State).

sign_in(<<>>, Req0, State) ->
    % Empty request
    { true, Req0, State };
sign_in(RequestBody, Req0, State) ->
  % TODO: Make email and password required
    Credentials  = jiffy:decode(RequestBody, [return_maps]),
    Email        = maps:get(<<"email">>, Credentials, <<"">>),

    Req1 = sign_in(
        'existingUser?',
        users_service:find_one(#{ "email" => Email }),
        Credentials,
        Req0,
        State
    ),
    { stop, Req1, State }.

sign_in('existingUser?', [], _Credentials, Req0, _State) ->
    respond_401(Req0),
    Req0;
sign_in('existingUser?', ExistingUser, Credentials, Req0, _State) ->
    Password     = binary_to_list(maps:get(<<"password">>, Credentials)),
    ExistingPass = maps:get("password", ExistingUser),
    sign_in(
        'passwordsMatch?',
        utils:compare_passwords(Password, ExistingPass),
        ExistingUser,
        Req0
    ).

sign_in('passwordsMatch?', false, _, Req0) ->
    respond_401(Req0),
    Req0;
sign_in('passwordsMatch?', true, User, Req0) ->
    cowboy_req:reply(200, #{ <<"content-type">> => <<"application/json">> },
        jiffy:encode({[
            { token, users_service:get_jwt(User) },
            { user, users_service:view(User) } 
        ]})
    , Req0).

respond_401(Req0) ->
    cowboy_req:reply(401, #{ <<"content-type">> => <<"application/json">> },
        jiffy:encode({[
            { error, <<"Wrong email/password">> }
        ]})
    , Req0).
