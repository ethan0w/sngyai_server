%%%-------------------------------------------------------------------
%%% @author yangyudong
%%% @copyright (C) 2014, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 九月 2014 上午12:29
%%%-------------------------------------------------------------------
-module(lib_exchange).
-author("yangyudong").

-include("record.hrl").
-include("common.hrl").

%% API
-export([
  exchange/4,
  get_all/0
  ]).

%%兑换
exchange(UserId, Type, Account, Num) ->
  case ets:lookup(?ETS_ONLINE, UserId) of
    [#user{score_current = SC}|_] ->
      case Num =< SC of
        true ->
          lib_user:add_score(UserId, -Num),
          Time = lib_util_time:get_timestamp(),
          ExchangeLog =
            #exchange_log{
              id = {UserId, Time},
              user_id = UserId,
              time = Time,
              type = Type,
              account = Account,
              num = Num
            },
          ets:insert(?ETS_EXCHANGE_LOG, ExchangeLog),
          db_agent_exchange_log:add(ExchangeLog);
        false ->
          "score_not_enough"
      end;
    _Other ->
      "user_not_exist"
  end.

get_all() ->
  List = ets:tab2list(?ETS_EXCHANGE_LOG),
  lists:concat(["[", concat_result(List, []), "]"]).

concat_result([], Result) ->
  Result;
concat_result([Exchange|T], Result) ->
  #exchange_log{
    user_id = UserId,
    time = Time,
    type = Type,
    account = Account,
    num = Num
  } = Exchange,
  CurResult = lists:concat(["{\"user_id\":\"", UserId,
    "\",\"time\":\"", Time,
    "\",\"type\":\"", Type,
    "\",\"account\":\"", Account,
    "\",\"num\":\"", Num,
    "\"}"
  ]),
  NewResult =
    case Result of
      [] ->
        CurResult;
      _Other ->
        lists:concat([Result, ",", CurResult])
    end,
  concat_result(T, NewResult).

