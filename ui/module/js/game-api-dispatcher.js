Logic.Dispatcher = new function() {
	var thisref = this;
	
	//Dispatch events
	(function(events) {
		for (var key in events) {
			if (events.hasOwnProperty(key));
			Logic.RequestEvents[key].add(events[key]);
		}
	})({
		getAccountState: function(data) {
			Data.Me.Id = data.state.id;
			Data.Me.Name = data.state.name;
		},
		getAccountName: function(data) {
			Data.Data.UserIdNameRef[data.user] = data.name;
		},
		createGroup: function(data) {
			Logic.Reaction.ShowGroup(data.group);
		},
		getGroup: function(data) {
			Logic.Reaction.ShowGroup(data.group);
		},
		addUserToGroupByKey: function(data) {
			if (Data.View.NewGameTab != null) {
				if (data.success) 
					Logic.Reaction.ShowGroup(data.group);
				else alert(Lang.Get("wrongKeyMessage"));
			}
		},
		getUserFromGroup: function(data) {
			if (Data.View.CurrentGames[data.group] != undefined)
				Data.View.CurrentGames[data.group].UpdateUser(data.user);
		},
		setUserOnline: function(data) {
			if (Data.View.CurrentGames[data.group] != undefined)
				Data.View.CurrentGames[data.group].UpdateUserOnline(data.user);
		},
		getGroupFromUser: function(data) {
			Data.View.UserGroups = data.group;
		}
		createGame: function(data) {
			if (Data.View.CurrentGames[data.game.mainGroupId] != undefined)
				Data.View.CurrentGames[data.game.mainGroupId].UpdateGameData(data.game);
		},
		getGame: function(data) {
			if (Data.View.CurrentGames[data.game.mainGroupId] != undefined)
				Data.View.CurrentGames[data.game.mainGroupId].UpdateGameData(data.game);
		},
		getPlayer: function(data) {
			if (Data.View.RunningGames[data.player.game] != undefined)
				Data.View.RunningGames[data.player.game].UpdatePlayer(data.player);
		},
		getAccessibleChatRooms: function(data) {
			if (Data.View.RunningGames[data.player.game] != undefined)
				Data.View.RunningGames[data.player.game].UpdateRoom(data.rooms);
		},
		getChatRoom: function(data){
			if (Data.View.ChatRoomGames[data.chat.id] != undefined)
				Data.View.ChatRoomGames[data.chat.id].UpdateRoomData(data.chat);
		},
		getPlayerInRoom: function(data) {
			if (Data.View.ChatRoomGames[data.chat] != undefined)
				Data.View.ChatRoomGames[data.chat].UpdateRoomPlayer(data.chat, data.player);
		},
		getLastChat: function(data) {
			if (Data.View.ChatRoomGames[data.room] != undefined)
				Data.View.ChatRoomGames[data.room].HandleNewChat(data.room, data.chat);
		},
		addChat: function(data) {
			if (Data.View.ChatRoomGames[data.room] != undefined)
				Data.View.ChatRoomGames[data.room].HandleNewChat(data.room, data.chat);
		},
		addVote: function(data) {
			if (Data.View.ChatRoomGames[data.vote.setting] != undefined)
				Data.View.ChatRoomGames[data.vote.setting].ShowClientVoteBox(data.vote.setting, true);
		},
		getVotesFromRoom: function(data) {
			if (Data.View.ChatRoomGames[data.room] != undefined)
				Data.View.ChatRoomGames[data.room].UpdateVotes(data.room, data.votes);
		},
		getVoteFromPlayer: function(data) {
			if (Data.View.ChatRoomGames[data.chat] != undefined)
				Data.View.ChatRoomGames[data.chat].ShowClientVoteBox(data.chat, data.vote != null);
		}
	});
	
};

Logic.Reaction = {
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
	
