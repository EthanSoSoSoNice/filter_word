-module(filter_connect_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
    PoolSize = application:get_env(game_server,filter_word_pool,8),
    supervisor:start_link({local, ?MODULE}, ?MODULE, [PoolSize]).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([Size]) ->
	Procs = [ {{filter_connect,N},{filter_connect,start_link,[]},permanent,brutal_kill,worker,[]} || N <- lists:seq(1,Size)],
	{ok,{{one_for_one,10,10},Procs}}.


