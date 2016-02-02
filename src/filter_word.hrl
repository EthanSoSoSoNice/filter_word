-ifndef(FILTER_WORD).
-define(FILTER_WORD, '').

-record(pool,
{
  work_queue :: queue:queue(),
  state :: dict:dict()
}).

-record(work,
{
  words :: map(),
  manager_ref :: ref()
}).

-endif.
