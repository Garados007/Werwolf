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
				try { element = JSON.parse(element); }
				catch (ex) {
					console.log(ex, element);
					return;
				}
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
		getAccountName: function(data) {
			Data.UserIdNameRef[data.user] = data.name;
			thisref.RequestEvents.getAccountName.invoke(data);
		},
		createGroup: function(data) {
			Logic.Reaction.ShowGroup(data.group);
			thisref.RequestEvents.createGroup.invoke(data);
		},
		getGroup: function(data) {
			Logic.Reaction.ShowGroup(data.group);
			thisref.RequestEvents.getGroup.invoke(data);
		},
		addUserToGroup: function(data) {
			thisref.RequestEvents.addUserToGroup.invoke(data);
		},
		addUserToGroupByKey: function(data) {
			if (Data.NewGameTab != null) {
				if (data.success) 
					Logic.Reaction.ShowGroup(data.group);
				else alert(Lang.Get("wrongKeyMessage"));
			}
			thisref.RequestEvents.addUserToGroup.invoke(data);
		},
		getUserFromGroup: function(data) {
			if (Data.CurrentGames[data.group] != undefined)
				Data.CurrentGames[data.group].UpdateUser(data.user);
			thisref.RequestEvents.getUserFromGroup.invoke(data);
		},
		getGroupFromUser: function(data) {
			Data.UserGroups = data.group;
			thisref.RequestEvents.getGroupFromUser.invoke(data);
		},
		createGame: function(data) {
			if (Data.CurrentGames[data.game.mainGroupId] != undefined)
				Data.CurrentGames[data.game.mainGroupId].UpdateGameData(data.game);
			thisref.RequestEvents.createGame.invoke(data);
		},
		getGame: function(data) {
			if (Data.CurrentGames[data.game.mainGroupId] != undefined)
				Data.CurrentGames[data.game.mainGroupId].UpdateGameData(data.game);
			thisref.RequestEvents.getGame.invoke(data);
		},
		
		getPlayer: function(data) {
			if (Data.RunningGames[data.player.game] != undefined)
				Data.RunningGames[data.player.game].UpdatePlayer(data.player);
			thisref.RequestEvents.getPlayer.invoke(data);
		},
		getAccessibleChatRooms: function(data) {
			if (Data.RunningGames[data.player.game] != undefined)
				Data.RunningGames[data.player.game].UpdateRoom(data.rooms);
			thisref.RequestEvents.getAccessibleChatRooms.invoke(data);
		},
		getChatRoom: function(data){
			if (Data.ChatRoomGames[data.chat.id] != undefined)
				Data.ChatRoomGames[data.chat.id].UpdateRoomData(data.chat);
			thisref.RequestEvents.getChatRoom.invoke(data);
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
		GetAccountName: function(user) {
			thisref.SendApiRequest({
				mode: "getAccountName",
				user: user
			});
		},
		CreateGroup: function(name, user) {
			thisref.SendApiRequest({
				mode: "createGroup",
				name: name,
				user: user
			});
		},
		GetGroup: function(id) {
			thisref.SendApiRequest({
				mode: "getGroup",
				group: id
			});
		},
		AddUserToGroupByKey: function(user, key) {
			thisref.SendApiRequest({
				mode: "addUserToGroupByKey",
				user: user,
				key: key
			});
		},
		GetGroupsFromUser: function(user) {
			thisref.SendApiRequest({
				mode: "getGroupFromUser",
				user: user
			});
		},
		CreateGame: function(group, roles) {
			thisref.ApiAccess.Multi([JSON.stringify({
				mode: "createGame",
				group: group,
				roles: roles
			})]);
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
					list.push(JSON.stringify({
						mode: "getGroup",
						group: Data.UserGroups[i]
					}));
				}
				if (list.length == 0) Logic.Reaction.InitNoGroup();
				else Logic.ApiAccess.Multi(list);
				var game = new WerWolf.AddGame();
				game.Attach();
			});
			Logic.RequestEvents.getAccountState.addSingle(function() {
				Logic.ApiAccess.GetGroupsFromUser(Data.UserId);
			});
			Logic.ApiAccess.GetAccountState();
		},
		InitNoGroup: function() {
			$(".tab-list").find(".loading-frame").remove();
			var game = new WerWolf.NewGame();
			game.Attach();
			game.Activate();
		},
		ShowGroup: function(group) {
			$(".tab-list").find(".loading-frame").remove();
			if (Data.CurrentGames[group.id] != undefined) {
				if (Data.CurrentGames[group.id].UpdateGroupInfo != undefined)
					Data.CurrentGames[group.id].UpdateGroupInfo(group);
			}
			else {
				if (group.currentGame == null) {
					var game = new WerWolf.PrepairGame(group.id, group);
					game.Attach();
					game.Activate();
				}
				else {
					var game = new WerWolf.PlayGame(group.id, group);
					game.Attach();
					game.Activate();
				}
				if (Data.NewGameTab != null) Data.NewGameTab.Remove();
			}
		}
	};
};

Data = {
	UserId: null,
	UserName: null,
	UserGroups: [],
	Games: [],
	NewGameTab: null,
	CurrentGames: {},
	UserIdNameRef: {},
	RunningGames: {},
	ChatRoomGames: {}
};

$(function(){
	$(".loading-box").addClass("close");
	//connect to server and load data
	UI.CreateLoadingIndicator().appendTo($(".main-content"));
	UI.CreateLoadingIndicator().css("font-size", "0.5em").appendTo($(".tab-list"));
	Logic.Reaction.InitPrepairData();
});