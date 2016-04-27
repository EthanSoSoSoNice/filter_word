# filter_word #

># idea
> the application is used for filter word

># Using
```erlang
	filter_word:start({local, word_filter}, 8, "./word.txt");  
	filter_word:filter(word_filter, <<"fuck"/utf8>>), %% result <<"****">>  
	filter_word:test(word_filter, <<"fuck"/utf8>>), %% boolean()
```

