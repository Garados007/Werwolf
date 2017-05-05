var Logic = new function() {
	var thisref = this;
	
	this.SendApiRequest = function(data) {
		$.post('/'+$WWV.urlBase+'api/', data, function(result) {
			thisref.RequestHandler.multi.call(
				thisref, {
					results: [ result ]
				});
		}, 'text');
	};
	
	this.RequestHandler = {
		multi: function(data) {
			data.results.forEach(function(element) {
				element = JSON.parse(element);
				if (!element.success)
					thisref.RequestHandler.error(element);
				else element = element.result;
				if (element.method == undefined)
					thisref.RequestHandler.error(element);
				else if (thisref.RequestHandler[element.method] == undefined)
					thisref.RequestHandler.notFound(element);
				else thisref.RequestHandler[element.method].call(thisref, element);
			});
			thisref.RequestEvents.multi.invoke(data);
		},
		notFound: function(data) {
			console.log("not found: ", data.method, data);
			thisref.RequestEvents.notFound.invoke(data);
		},
		error: function(data) {
			console.error(data);
			thisref.RequestEvents.error.invoke(data);
		},
		getAccountState: function(data) {
			Data.UserId = data.state.id;
			Data.UserName = data.state.name;
			thisref.RequestEvents.getAccountState.invoke(data);
		},
		
		getGroupFromUser: function(data) {
			Data.UserGroups = data.group;
			thisref.RequestEvents.getGroupFromUser.invoke(data);
		}
	};
	
	this.ApiAccess = {
		Multi: function(requests) {
			var tasks = [];
			for (var i = 0; i<requests.length; ++i)
				tasks.push(JSON.stringify(requests[i]));
			if (tasks.length == 0) return;
			thisref.SendApiRequest({
				mode: "multi",
				"tasks[]": tasks
			});
		},
		GetAccountState: function() {
			thisref.SendApiRequest({
				mode: "getAccountState"
			});
		},
		CreateGroup: function(name, user) {
			thisref.SendApiRequest({
				mode: "createGroup",
				name: name,
				user: user
			});
		},
		
		GetGroupsFromUser: function(user) {
			thisref.SendApiRequest({
				mode: "getGroupFromUser",
				user: user
			});
		}
	};
	
	this.RequestEvents = {};
	for (var key in this.RequestHandler) {
		this.RequestEvents[key] = new ToolKit.Event();
	}

	this.Reaction = {
		InitPrepairData: function() {
			Logic.RequestEvents.getGroupFromUser.addSingle(function() {
				var list = [];
				for (var i = 0; i<Data.UserGroups.length; ++i) {
					Logic.Reaction.InitGroup(Data.UserGroups[i]);
					list.push(JSON.stringify({
						mode: "getGroup",
						group: Data.UserGroups[i]
					}));
				}
				if (list.length == 0) Logic.Reaction.InitNoGroup();
				else Logic.ApiAccess.Multi(list);
			});
			Logic.RequestEvents.getAccountState.addSingle(function() {
				Logic.ApiAccess.GetGroupsFromUser(Data.UserId);
			});
			Logic.ApiAccess.GetAccountState();
		},
		InitGroup: function(id) {
			
		},
		InitNoGroup: function() {
			$(".tab-list").find(".loading-frame").remove();
			var game = new WerWolf.Game();
			game.Attach();
		}
	};
};

Data = {
	UserId: null,
	UserName: null,
	UserGroups: [],
	Games: []
};

$(function(){
	$(".loading-box").addClass("close");
	//connect to server and load data
	UI.CreateLoadingIndicator().appendTo($(".main-content"));
	UI.CreateLoadingIndicator().css("font-size", "0.5em").appendTo($(".tab-list"));
	Logic.Reaction.InitPrepairData();
});