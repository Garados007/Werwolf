var Logic = Logic || {};

Logic.SendApiRequest = function(data) {
	$.post('/'+$WWV.urlBase+'api/', data, function(result) {
		thisref.RequestHandler.multi.call(
			thisref, {
				results: [ result ]
			});
	}, 'text');
};

Logic.RequestHandler = {
	multi: function(data) {
		data.results.forEach(function(element) {
			try { element = JSON.parse(element); }
			catch (ex) {
				console.log(ex, element);
				return;
			}
			if (element.maintenance) {
				document.location.href="/"+$WWV.urlBase+"ui/maintenance/";
				return;
			}
			if (!element.success)
				Logic.RequestHandler.error(element);
			else element = element.result;
			if (element.method == undefined)
				Logic.RequestHandler.error(element);
			else if (Logic.RequestHandler[element.method] == undefined)
				Logic.RequestHandler.notFound(element);
			else Logic.RequestHandler[element.method].call(Logic, element);
		});
		Logic.RequestEvents.multi.invoke(data);
	},
	notFound: function(data) {
		console.log("not found: ", data.method, data);
		thisref.RequestEvents.notFound.invoke(data);
	},
	error: function(data) {
		console.error(data);
		thisref.RequestEvents.error.invoke(data);
	}
};

Logic.RequestEvents = {
	multi: new ToolKit.Event(),
	notFound: new ToolKit.Event(),
	error: new ToolKit.Event()
};

(function() {
	var functions = [
		"getAccountState", "getAccountName", "createGroup", "getGroup",
		"addUserToGroup", "addUserToGroupByKey", "getUserFromGroup",
		"setUserOnline", "getGroupFromUser", "removeCurrentGame",
		"createGame", "getGame", "nextRound", "getPlayer", 
		"getAccissibleChatRooms", "getChatRoom", "getPlayerInRoom",
		"getLastChat", "addChat", "createVoting", "endVoting",
		"addVote", "getVotesFromRoom", "getVoteFromPlayer"
	];
	var setter = function(name) {
		Logic.RequestEvents[name] = new ToolKit.Event();
		Logic.RequestHandler[name] = function(data) {
			Logic.RequestEvents[name].invoke(data);
		};
	};
	for (var i = 0; i<functions.length; ++i)
		setter(functions[i]);
})();

