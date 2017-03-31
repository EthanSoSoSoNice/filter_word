-ifndef(FILTER_WORD).
-define(FILTER_WORD, '').

-record(pool,
{
  worker_queue :: queue:queue(),
  ttree :: dict:dict()
}).

-record(work,
{
  words :: map(),
  manager_ref 
}).

-endif.
