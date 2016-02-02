-module(utf8_convert_utf16).

-export([utf8_convert_utf16/1]).


utf8_convert_utf16(StrBin) ->
	utf8_convert_utf16(StrBin,[]).
utf8_convert_utf16(<<>>,Acc)->
	lists:reverse(Acc);
utf8_convert_utf16(<<0:1 , A:7,Rest/binary>>,Acc)->
	utf8_convert_utf16(Rest,[ A | Acc ]);
utf8_convert_utf16(<<6:3,  A:5, 2:2, B:6 ,Rest/binary>>,Acc)->
	utf8_convert_utf16(Rest,[(A bsl 6) + B | Acc]);	
utf8_convert_utf16(<<14:4, A:4, 2:2, B:6, 2:2, C:6,Rest/binary>>,Acc)->
	utf8_convert_utf16(Rest,[(A bsl 12) + (B bsl 6) + C | Acc]);
utf8_convert_utf16(<<30:5, _A:3, 2:2, _B:6, 2:2, _C:6, 2:2, _D:6, Rest/binary>>,Acc)->
%% 	utf8_convert_utf16(Rest,[(A bsl 18) + (B bsl 12) + (C bsl 6) + D | Acc]);
  utf8_convert_utf16(Rest,[ 0 | Acc]);
utf8_convert_utf16(Bin,Acc)->
	io:format("ucs Error: Bin=~p~n     Acc=~p~n     ",[Bin,Acc]),
    {error,not_utf8}.