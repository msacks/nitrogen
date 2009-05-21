% Nitrogen Web Framework for Erlang
% Copyright (c) 2008-2009 Rusty Klophaus
% See MIT-LICENSE for licensing information.

-module (default_route_handler).
-behaviour (route_handler).
-include ("wf.inc").
-include ("simplebridge.hrl").
-export ([
	init/1, 
	finish/2,
	route/2
]).

init(Context) -> 
	{ok, Context, []}.
	
finish(Context, State) -> 
	{ok, Context, State}.

route(Context, State) -> 
	% Get the path.
	Bridge = Context#context.request,
	Path = Bridge:path(),
	?PRINT(Path),
	
	% Turn the path into a module and pathinfo.
	{Module, PathInfo} = path_to_module(Path),
	?PRINT({Module, PathInfo}),
	
	% Update the context and return.
	NewContext = Context#context {
		page_module=Module,
		path_info=PathInfo
	},
	{ok, NewContext, State}.
	

%%% PRIVATE FUNCTIONS %%%

%% path_to_module/1 - Convert a web path to a module.
path_to_module(undefined) -> {web_index, ""};
path_to_module(S) -> 
	case lists:last(S) of
		$/ -> 
			S1 = S ++ "index",
			tokens_to_module(string:tokens(S1, "/"), [], true);
		_ -> 
			tokens_to_module(string:tokens(S, "/"), [], false)
	end.
	
tokens_to_module([], PathInfoAcc, AddedIndex) -> {web_404, to_path_info(PathInfoAcc, AddedIndex)};
tokens_to_module(Tokens, PathInfoAcc, AddedIndex) ->
	try
		% Try to get the name of a module.
		ModuleString = string:join(Tokens, "_"),
		Module = list_to_existing_atom(ModuleString),
		
		% Moke sure the module is loaded.
		code:ensure_loaded(Module),
		{Module, to_path_info(PathInfoAcc, AddedIndex)}
	catch _ : _ -> 
		% Strip off the last token, and try again.
		LastToken = lists:last(Tokens),
		Tokens1 = lists:reverse(tl(lists:reverse(Tokens))),
		tokens_to_module(Tokens1, [LastToken|PathInfoAcc], AddedIndex)
	end.	
	
chop_last_element(L) -> lists:reverse(tl(lists:reverse(L))).
to_path_info([], _) -> "";
to_path_info(PathInfoAcc, true)  -> string:join(chop_last_element(PathInfoAcc), "/");
to_path_info(PathInfoAcc, false) -> string:join(PathInfoAcc, "/").