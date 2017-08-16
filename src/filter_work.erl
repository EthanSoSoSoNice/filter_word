%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. 二月 2016 15:46
%%%-------------------------------------------------------------------
-module(filter_work).
-include("filter_word.hrl").
-author("Administrator").

-behaviour(gen_server).

%% API
-export([start_link/2]).
-export([init/1]).
-export([handle_call/3]).
-export([handle_cast/2]).
-export([handle_info/2]).
-export([terminate/2]).
-export([code_change/3]).

start_link(MgrRef, Words)->
  gen_server:start_link(?MODULE, [MgrRef, Words], []).

init([MgrRef, Words])->
  gen_server:cast(MgrRef, {add, self()}),
  {ok, #work{ manager_ref = MgrRef, words = Words} }.


handle_cast(_Msg, State)->
  {noreply, State}.

handle_call({test, Str}, _Form, State)->
  {reply, test(Str, State#work.words), State};
handle_call({filter, Str}, _Form, State)->
  {reply, filter(Str, State#work.words), State};
handle_call(_Msg, _Form, State)->
  {reply, ok, State}.

handle_info(_Msg, State)->
  {noreply, State}.

code_change(_Old, State, _Extra)->
  {ok, State}.

terminate(_Reason, #work{manager_ref = MgrRef})->
  gen_server:cast(MgrRef, {terminate, self()}).



is_end(#{ "e" := End })->
  End =:= 1.


get_value(Map, Key)->
  case maps:find(Key, Map) of
    {ok, Value}->
      Value;
    _->
      error({"does not contain the key in the specified Map", maps:keys(Map), maps:values(Map)})
  end.

is_contain(_Map, [])->
  false;
is_contain(Map, [H|_T])->
  maps:is_key(H, Map);
is_contain(Map, Key)->
  maps:is_key(Key, Map).

filter(L, State) when is_list(L) ->
  filter(L, State, 0, [], State);
filter(Bin, State) when is_binary(Bin) ->
  L = filter_word:utf8_convert_utf16(Bin),
  filter(L, State, 0, [], State).

filter([], _, _, Acc, _InitState)->
  unicode:characters_to_binary(lists:reverse(Acc), utf16);
%%%  Prevent users input spaces in the sensitive word
%%%
%%%
filter([H|T], State, 0, Acc, InitState) when  H =:= 16#3000 orelse H =:= 16#20 ->
  filter(T, State, 0, [H|Acc], InitState);
filter([H|T], State, I, Acc, InitState) when H =:= 16#3000 orelse H =:= 16#20->
  filter(T, State, I + 1, [H|Acc], InitState);
filter([H|T] ,State,I,Acc, InitState)->
  case is_contain(State,H) of
    true->
      NewState = get_value(State,H),
      case is_end(NewState) of
        true->
          NewAcc = replace([ H | Acc], I + 1),
          case is_contain(NewState,T) of
            true->
              filter(T, NewState, 0 ,NewAcc, InitState);
            false->
              filter(T, InitState, 0, NewAcc, InitState)
          end;
        false->
          case is_contain(NewState, T) orelse ( T =/= [] andalso ( hd(T) =:= 16#20 orelse hd(T) =:= 16#3000 ) )  of
            true->
              filter(T,NewState,I + 1,[H | Acc], InitState);
            false->
              filter(T, InitState, 0,[H|Acc], InitState)
          end
      end;
    false->
      filter(T, InitState, 0, [H | Acc], InitState)
  end.


test(L, State) when is_list(L) ->
  test(L, State, State);
test(Bin, State) when is_binary(Bin) ->
  L = filter_word:utf8_convert_utf16(Bin),
  test(L, State, State).
test([],_, _)->
  true;
test([H|T] = L, State, InitState)->
  case is_contain(State,H) of
    true->
      NewState = get_value(State,H),
      case is_end(NewState) of
        true->
          false;
        false->
          test(T,NewState, InitState)
      end;
    false->
      case is_contain(InitState,H) of
        true->
          test(L,InitState, InitState);
        false->
          test(T,InitState, InitState)
      end
  end.


replace(L,I)->
  replace(L,I,[]).
replace([_H|T], 1,Acc)->
  lists:reverse([2#101010|Acc]) ++ T;
replace([_H|T],I,Acc)->
  replace(T,I - 1,[2#101010|Acc]).
