-module(users).
-export([
  init/2,
  allowed_methods/2,
  content_types_accepted/2,
  content_types_provided/2,
  get_json/2,
  post_json/2,
  delete_resource/2
]).

% Generic
init(Req0, State) ->
	{ cowboy_rest, Req0, State }.

allowed_methods(Req0, State) ->
	{ [<<"GET">>, <<"POST">>, <<"DELETE">>], Req0, State }.

content_types_accepted(Req0, State) ->
  { [ { { <<"application">>, <<"json">>, [] }, post_json } ], Req0, State }.

content_types_provided(Req0, State) ->
	{ [ { { <<"application">>, <<"json">>, [] }, get_json } ], Req0, State }.

% TODO Users controllers
get_json(Req0, State) ->
    { <<"{\"rest\": \"Getting users!\"}">>, Req0, State }.

post_json(Req0, State) ->
    { true, Req0, State }.

delete_resource(Req0, State) ->
    { ok, Req0, State }.
