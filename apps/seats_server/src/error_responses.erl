-module(error_responses).

-export([
    respond_400/1,
    respond_401/1,
    respond_404/1,
    reject_409_with_message/2
]).

respond_400(Req0) ->
    cowboy_req:reply(400, #{ <<"content-type">> => <<"application/json">> },
        jiffy:encode({[
            { error, <<"Bad request.">> }
        ]})
    , Req0).

respond_401(Req0) ->
    cowboy_req:reply(401, #{ <<"content-type">> => <<"application/json">> },
        jiffy:encode({[
            { error, <<"Wrong email/password">> }
        ]})
    , Req0).

respond_404(Req0) ->
    cowboy_req:reply(404, #{ <<"content-type">> => <<"application/json">> },
        jiffy:encode({[
            { error, <<"Resource not found.">> }
        ]})
    , Req0).

reject_409_with_message(Req0, Message) ->
    ResponseBody = jiffy:encode({[
        { error, Message }
    ]}),

    cowboy_req:reply(409, #{
        <<"content-type">> => <<"application/json">>
    }, ResponseBody, Req0).