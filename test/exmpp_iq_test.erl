-module(exmpp_iq_test).

-include_lib("eunit/include/eunit.hrl").

-include("exmpp.hrl").


get_test() ->
	Q = {xmlel, <<"pubsub">>, [{<<"xmlns">>, <<"http://jabber.org/protocol/pubsub">>}], 
	   [{xmlel, <<"subscriptions">>, [], []}]},
	G = exmpp_iq:get(Q),
	?assertMatch({xmlel, <<"iq">>, _, _}, G),
	?assertEqual(<<"get">>, exxml:get_attr(G, <<"type">>)),
	?assertEqual([Q], exxml:get_els(G)),
	?assert(exxml:get_attr(G, <<"id">>) /= undefined),
	ok.

set_test() ->
	Q = {xmlel, <<"pubsub">>, [{<<"xmlns">>, <<"http://jabber.org/protocol/pubsub">>}], 
	   [{xmlel, <<"subscriptions">>, [], []}]},
	G = exmpp_iq:set(Q),
	?assertMatch({xmlel, <<"iq">>, _, _}, G),
	?assertEqual(<<"set">>, exxml:get_attr(G, <<"type">>)),
	?assertEqual([Q], exxml:get_els(G)),
	?assert(exxml:get_attr(G, <<"id">>) /= undefined),
	ok.
	   
result_test() ->
	From = <<"from.com">>,
	To = <<"to.com">>,
	Q = {xmlel, <<"pubsub">>, [{<<"xmlns">>, <<"http://jabber.org/protocol/pubsub">>}], 
	   [{xmlel, <<"subscriptions">>, [], []}]},
   	Q2 = exxml:set_attr(exxml:set_attr(exmpp_iq:get(Q), <<"from">>, From), <<"to">>, To),
	R = exmpp_iq:result(Q2),
	?assertMatch({xmlel, <<"iq">>, _, _} , R),
	?assertEqual(<<"result">>, exxml:get_attr(R, <<"type">>)),
	?assertEqual(From, exxml:get_attr(R, <<"to">>)),
	?assertEqual(To, exxml:get_attr(R, <<"from">>)),

	IQR = exmpp_iq:result(exmpp_iq:xmlel_to_iq(Q2), {xmlel, <<"result">>, [{<<"xmlns">>, <<"sample">>}], []}),
	?assertEqual({xmlel, <<"result">>, [{<<"xmlns">>, <<"sample">>}], []}, IQR#iq.payload),
	?assertEqual(<<"result">>, exmpp_iq:get_type(IQR)),
	?assertEqual(<<"sample">>, exmpp_iq:get_payload_ns(IQR)),
	?assertEqual(<<"sample">>, IQR#iq.ns),
	ok.


error2_test() ->
	From = <<"from.com">>,
	To = <<"to.com">>,
	Q = {xmlel, <<"pubsub">>, [{<<"xmlns">>, <<"http://jabber.org/protocol/pubsub">>}], 
	   [{xmlel, <<"subscriptions">>, [], []}]},
   	Q2 = exxml:set_attr(exxml:set_attr(exmpp_iq:get(Q), <<"from">>, From), <<"to">>, To),
	E = exmpp_iq:error(Q2, <<"forbidden">>),
	?assertMatch({xmlel, <<"iq">>, _, _} , E),
	?assertEqual(<<"error">>, exxml:get_attr(E, <<"type">>)),
	?assertEqual(From, exxml:get_attr(E, <<"to">>)),
	?assertEqual(To, exxml:get_attr(E, <<"from">>)),
	?assertMatch({xmlel, <<"forbidden">>, _, _}, 
		exxml:get_path(E, [{element, <<"error">>}, {element, <<"forbidden">>}])),
	?assertEqual(<<"urn:ietf:params:xml:ns:xmpp-stanzas">>, 
		exxml:get_path(E, [{element, <<"error">>}, {element, <<"forbidden">>}, {attribute, <<"xmlns">>}])),
	ok.
error3_test() ->
	From = <<"from.com">>,
	To = <<"to.com">>,
	Q = {xmlel, <<"pubsub">>, [{<<"xmlns">>, <<"http://jabber.org/protocol/pubsub">>}], 
	   [{xmlel, <<"subscriptions">>, [], []}]},
   	Q2 = exxml:set_attr(exxml:set_attr(exmpp_iq:get(Q), <<"from">>, From), <<"to">>, To),
	E = exmpp_iq:error(Q2, <<"forbidden">>, <<"this is the cause">>),
	?assertMatch({xmlel, <<"iq">>, _, _} , E),
	?assertEqual(<<"error">>, exxml:get_attr(E, <<"type">>)),
	?assertEqual(From, exxml:get_attr(E, <<"to">>)),
	?assertEqual(To, exxml:get_attr(E, <<"from">>)),
	?assertMatch({xmlel, <<"forbidden">>, _, _}, 
		exxml:get_path(E, [{element, <<"error">>}, {element, <<"forbidden">>}])),
	?assertEqual(<<"urn:ietf:params:xml:ns:xmpp-stanzas">>, 
		exxml:get_path(E, [{element, <<"error">>}, {element, <<"forbidden">>}, {attribute, <<"xmlns">>}])),
	?assertEqual(<<"urn:ietf:params:xml:ns:xmpp-stanzas">>, 
		exxml:get_path(E, [{element, <<"error">>}, {element, <<"text">>}, {attribute, <<"xmlns">>}])),
	?assertEqual(<<"this is the cause">>, 
		exxml:get_path(E, [{element, <<"error">>}, {element, <<"text">>}, cdata])),
	ok.


error_without_original_test() ->
	From = <<"from.com">>,
	To = <<"to.com">>,
	Q = {xmlel, <<"pubsub">>, [{<<"xmlns">>, <<"http://jabber.org/protocol/pubsub">>}], 
	   [{xmlel, <<"subscriptions">>, [], []}]},
   	Q2 = exxml:set_attr(exxml:set_attr(exmpp_iq:get(Q), <<"from">>, From), <<"to">>, To),
	E = exmpp_iq:error_without_original(Q2, <<"forbidden">>),
	?assertMatch({xmlel, <<"iq">>, _, _} , E),
	?assertEqual(<<"error">>, exxml:get_attr(E, <<"type">>)),
	?assertEqual(From, exxml:get_attr(E, <<"to">>)),
	?assertEqual(To, exxml:get_attr(E, <<"from">>)),
	?assertMatch({xmlel, <<"forbidden">>, _, _}, 
		exxml:get_path(E, [{element, <<"error">>}, {element, <<"forbidden">>}])),
	?assertEqual(<<"urn:ietf:params:xml:ns:xmpp-stanzas">>, 
		exxml:get_path(E, [{element, <<"error">>}, {element, <<"forbidden">>}, {attribute, <<"xmlns">>}])),
	?assertEqual(1, length(exxml:get_els(E))),
	ok.


conversions_test() ->
	S = <<"<iq type='get' from='romeo@montague.net/orchard' to='plays.shakespeare.lit' id='info1'>", 
	"<query xmlns='http://jabber.org/protocol/disco#info'/> </iq>">>,
	{ok, [Q]} = exxml:parse_document(S),
	IQ = exmpp_iq:xmlel_to_iq(Q),
	?assertEqual(<<"get">>, IQ#iq.type),
	?assertEqual(request, IQ#iq.kind),
	?assertEqual(<<"info1">>, IQ#iq.id),
	?assertEqual(<<"http://jabber.org/protocol/disco#info">>, IQ#iq.ns),
	
	Q2 = exmpp_iq:iq_to_xmlel(IQ),
	?assertMatch({xmlel, <<"iq">>, _, _}, Q2),
	?assertEqual(<<"http://jabber.org/protocol/disco#info">>, 
		exxml:get_path(Q2, [{element, <<"query">>}, {attribute, <<"xmlns">>}])),
	ok.


is_iq_test() ->
	S = <<"<iq type='get' from='romeo@montague.net/orchard' to='plays.shakespeare.lit' id='info1'>", 
	"<query xmlns='http://jabber.org/protocol/disco#info'/> </iq>">>,
	{ok, [Q]} = exxml:parse_document(S),
	?assert(exmpp_iq:is_iq(Q)),
	?assertNot(exmpp_iq:is_iq({xmlel, <<"message">>, [], []})),
	ok.
is_iq_record_test() ->
	S = <<"<iq type='get' from='romeo@montague.net/orchard' to='plays.shakespeare.lit' id='info1'>", 
	"<query xmlns='http://jabber.org/protocol/disco#info'/> </iq>">>,
	{ok, [Q]} = exxml:parse_document(S),
	?assert(exmpp_iq:is_iq_record(exmpp_iq:xmlel_to_iq(Q))),
	ok.



