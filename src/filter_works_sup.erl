-module(filter_works_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).
-export([start_child/2]).

%% Supervisor callbacks
-export([init/1]).

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([]) ->
  RestartStrategy = {simple_one_for_one, 0, 1},
  ChildSpec = {filter_work, {filter_work, start_link, []}, brutal_kill, 0, worker, [filter_work]},
  {ok, {RestartStrategy, [ChildSpec]}}.


start_child(MgrRef, Words)->
  supervisor:start_child(?MODULE, [MgrRef, Words]).
