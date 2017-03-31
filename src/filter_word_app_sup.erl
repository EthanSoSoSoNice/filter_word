%%%-------------------------------------------------------------------
%%% @author 11726
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. 十一月 2016 18:20
%%%-------------------------------------------------------------------
-module(filter_word_app_sup).
-author("11726").

%% API
-export([]).

%% Application callbacks
-export([
    start_link/0,
    init/1
]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start_link() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init(_) ->
  Childs = [
    {filter_word_sup, {filter_word_sup, start_link, []}, permanent, 5000, worker, [filter_word_sup]}
  ],
  {ok, { {one_for_one, 5, 10}, Childs} }.
