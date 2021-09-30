-module(seats_server).
-behaviour(application).

-export([start/2]).
-export([stop/1]).

start(_Type, _Args) ->
	db:connect(),

	Dispatch = cowboy_router:compile([
		{'_', [
			% JWT
			{"/users", users, []},
			{"/users/:userId", user, []},
			{"/users/:userId/venues", venues_of_user, []},
			{"/venues/:venueId", venue, []},
			{"/venues", venues, []},
			% Master Key
			{"/auth/sign-in", sign_in, []},
			{"/auth/sign-up", sign_up, []}
		]}
	]),
	{ok, _} = cowboy:start_clear(
        http,
        [{port, 8080}],
        #{
            env => #{
				dispatch => Dispatch
			},
            middlewares => [
				cowboy_router,
				authorization, % Choice of authentication strategy is done here
				cowboy_handler
			]
        }
    ),
	seats_server_sup:start_link().

stop(_State) ->
	ok = cowboy:stop_listener(http).
