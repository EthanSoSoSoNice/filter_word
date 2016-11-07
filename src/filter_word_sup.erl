-module(filter_word_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).
-export([
    start_child/2,
    stop_child/1
]).

%% Supervisor callbacks
-export([init/1]).

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

start_child(Ref, Args) ->
    supervisor:start_child(?MODULE,
        {Ref, {filter_word, start_link, [Ref|Args]}, permanent, 5000, worker, [filter_word]}
    ).

stop_child(Ref) ->
    supervisor:terminate_child(?MODULE, Ref).
%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([]) ->
    {ok, { {one_for_one, 5, 10}, []} }.

