%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2016,  <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. 二月 2016 15:08
%%%-------------------------------------------------------------------
-module(filter_word).
-author("Administrator").
-include("filter_word.hrl").


%% API
-export([ start/3,
          filter/2,
          test/2
]).



-behaviour(gen_server).
-export([init/1]).
-export([handle_call/3]).
-export([handle_cast/2]).
-export([handle_info/2]).
-export([code_change/3]).
-export([terminate/2]).

start(PoolRef,  Size,  WordTextPath)->
  gen_server:start_link(PoolRef,  ?MODULE,  [Size,  WordTextPath],  []).


init([PoolSize,  WordTextPath])->
  State = compile(WordTextPath),
  %% todo open work
  start_works(PoolSize,  State),
  {ok,   #pool{ state = State, work_queue = queue:new()}}.

-spec filter(Ref,  Utf8TextBinary)-> Utf16TextBinary
when 
	  Ref :: any(),
	  Utf8TextBinary :: binary(),  %% encode utf8
      Utf16TextBinary :: binary(). %% encode utf16

filter(Ref,  Text)
  when is_binary(Text)->
  WorkPid = take_work(Ref),
  gen_server:call(WorkPid,  {filter,  Text}).

test(Ref,  Text)
  when is_binary(Text)->
  WorkPid = take_work(Ref),
  gen_server:call(WorkPid,  {test,  Text}).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


handle_call(take,  _Form,  #pool{ work_queue = Works} = Pool ) ->
  {{value,  Work},  Works2} = queue:out(Works),
  {reply,  Work,  Pool#pool{work_queue = queue:in(Work,  Works2)}}.

handle_cast({add,  Work}, #pool{ work_queue = Works } = Pool)->
  {noreply, Pool#pool{ work_queue = queue:in(Work,  Works)}};
handle_cast(_Msg,  State)->
  {noreply,  State}.

handle_info(_Msg,  State)->
  {noreply,  State}.

code_change(_Old,  State,  _Extra)->
  {ok,  State}.

terminate(_Reason,  _State)->
  ok.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
start_works(Size,  Words)->
  [filter_work:start_link(self(),  Words) || _ <- lists:seq(1,  Size)].

take_work(Ref)->
  gen_server:call(Ref, take).

compile(FileName)->
  case catch get_file_io(FileName)  of
    {'EXIT',  Reason }->
      error(Reason);
    IO->
      init_state(IO,  #{ "e" => 0 } )
  end.



init_state(IO,  Map)->
  case file:read_line(IO) of
    {ok, Data}->
      Content = utf8_convert_utf16(list_to_binary(Data)),
      case Content of
        {error,  Reason}->
          error(Reason);
        _->
          NewMap = set_state(Map,  Content),
          init_state(IO, NewMap)
      end;
    eof->
      file:close(IO),
      Map;
    {error, Reason}->
      error({"IO read line failed", Reason})
  end.

set_state(Map, [H])->
  case is_contain(Map, H) of
    true->
      Map2 = get_value(Map, H),
      Map3 = put_value("e", 1, Map2),
      put_value(H, Map3, Map);
    false->
      NewMap = put_value("e", 1, maps:new()),
      put_value(H, NewMap, Map)
  end;
set_state(Map, [H, 2#1010])->
  set_state(Map, [H]);
set_state(Map, [H|Tail])->
  case is_contain(Map, H) of
    true->
      Map2 = get_value(Map, H),
      Map3 = set_state(Map2, Tail),
      put_value(H, Map3, Map);
    false->
      Map2 = set_state(maps:new(), Tail),
      Map3 = put_value("e", 0, Map2),
      put_value(H, Map3, Map)
  end;
set_state(Map, H)->
  case is_contain(Map, H) of
    true->
      Map;
    false->
      put_value(H, maps:new(), Map)
  end.


get_file_io(FileName)->
  case file:open(FileName, [read]) of
    {ok, IO}->
      IO;
    {error, Reason}->
      error({"file open failed", FileName, Reason})
  end.
get_value(Map, Key)->
  case maps:find(Key, Map) of
    {ok, Value}->
      Value;
    _->
      error({"does not contain the key in the specified Map",  maps:keys(Map),  maps:values(Map)})
  end.

is_contain(_Map,  [])->
  false;
is_contain(Map,  [H|_T])->
  maps:is_key(H, Map);
is_contain(Map, Key)->
  maps:is_key(Key, Map).


put_value(Key, Value, Map)->
  maps:put(Key,  Value,  Map).

utf8_convert_utf16(StrBin) ->
  utf8_convert_utf16(StrBin, []).
utf8_convert_utf16(<<>>, Acc)->
  lists:reverse(Acc);
utf8_convert_utf16(<<0:1, A:7, Rest/binary>>, Acc)->
  utf8_convert_utf16(Rest, [ A | Acc ]);
utf8_convert_utf16(<<6:3, A:5, 2:2, B:6, Rest/binary>>, Acc)->
  utf8_convert_utf16(Rest, [(A bsl 6) + B | Acc]);
utf8_convert_utf16(<<14:4, A:4, 2:2, B:6, 2:2, C:6, Rest/binary>>, Acc)->
  utf8_convert_utf16(Rest, [(A bsl 12) + (B bsl 6) + C | Acc]);
utf8_convert_utf16(<<30:5, _A:3,  2:2, _B:6, 2:2, _C:6, 2:2, _D:6, Rest/binary>>, Acc)->
%% 	utf8_convert_utf16(Rest, [(A bsl 18) + (B bsl 12) + (C bsl 6) + D | Acc]);
  utf8_convert_utf16(Rest, [ 0 | Acc]);
utf8_convert_utf16(_,  _)->
  {error,  "input encode is utf8"}.
