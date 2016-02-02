-module(filter_connect).


-define(CONNECT_MGR, filter_word).
-define(TernaryOperator(B,A,C),if B -> A; true-> C end).
-behavior(gen_server).

-export([start_link/0]).
-export([init/1]).
-export([handle_cast/2]).
-export([handle_call/3]).
-export([handle_info/2]).
-export([code_change/3]).
-export([terminate/2]).

start_link()->
	gen_server:start_link(?MODULE,[],[]).

init(_)->
  process_flag(trap_exit, true),
  gen_server:cast(self(),init),
	{ok,#{}}.


handle_cast(init, _)->
  State = gen_server:call(?CONNECT_MGR,{add, self()}),
  {noreply, State};
handle_cast(_Msg,State)->
	{noreply,State}.

handle_call({test,Str},_Form,State)->
	{reply,test(Str,State,State),State};
handle_call({filter,Str},_Form,State)->
	{reply,filter(Str,State,State),State};
handle_call(_Msg,_Form,State)->
	{reply,ok,State}.

handle_info(_Msg,State)->
	{noreply,State}.

code_change(_Old,State,_Extra)->
	{ok,State}.

terminate(Reason,_State)->
  gen_server:cast(?CONNECT_MGR,{terminate,self()}),
	error_logger:error_msg("~p~n~p~n",[?MODULE,Reason]).



is_end(#{ "e" := End })->
	End =:= 1.


get_value(Map,Key)->
	case maps:find(Key,Map) of
		{ok,Value}->
			Value;
		_->
			error({"does not contain the key in the specified Map",maps:keys(Map),maps:values(Map)})
	end.

is_contain(_Map,[])->
	false;
is_contain(Map,[H|_T])->
	maps:is_key(H,Map);
is_contain(Map,Key)->
	maps:is_key(Key,Map).

filter(Bin,State,InitState) when is_binary(Bin) ->
	L = utf8_convert_utf16:utf8_convert_utf16(Bin),
	filter(L,State,0,[], InitState).

filter([],_,_,Acc, _InitState)->
	unicode:characters_to_binary(lists:reverse(Acc));
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


test(Bin,State, InitState) when is_binary(Bin) ->
	L = utf8_convert_utf16:utf8_convert_utf16(Bin),
	test(L,State, InitState);
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


% timestamp()->
%   {_, S, MS} = os:timestamp(),
%   S * 1000000 + MS.