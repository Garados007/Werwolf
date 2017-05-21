WerWolf.PlayGame = function(id, data) {
	var thisref = this;
	WerWolf.RunningGame.call(this, id, data);
	//fallback
	if (data.currentGame == null) {
		thisref.Remove();
		return;
	}
	//normal
	Data.RunningGames[data.currentGame.id] = this;
	this.LoopEvents.push(JSON.stringify({
		mode: "getGame",
		game: data.currentGame.id
	}));
	
	Logic.ApiAccess.Multi([JSON.stringify({
		mode: "getUserFromGroup",
		group: this.id
	}),JSON.stringify({
		mode: "getPlayer",
		game: data.currentGame.id,
		user: Data.UserId,
		me: Data.UserId
	}),JSON.stringify({
		mode: "getAccessibleChatRooms",
		game: data.currentGame.id,
		user: Data.UserId
	})]);
	
	this.UpdateGroupInfo = function(data) {
		if (data.currentGame == null) {
			thisref.Remove();
			var game = new WerWolf.PrepairGame(data.id, data);
			game.Attach();
			game.Activate();
		}
	};
	
	var lastPhase = null;
	var currentGame = null;
	var lastGame = {};
	var rooms = {};
	this.UpdateGameData = function(game) {
		currentGame = game;
		if (lastPhase != game.phase.current) {
			lastPhase = game.phase.current;
			console.log(game.phase.current, game.phase.currentLevel);
			thisref.OrderTabs();
			for (var key in rooms)
				Logic.ApiAccess.GetPlayerInRoom(key);
		}
		if (game.finished != null && lastGame.finished == null) {
			var rooms = thisref.content.find(".chat-room-box");
			for (var i = 0; i<rooms.length; ++i) {
				var room = rooms.eq(i);
				if (room.hasClass("chat-story")) {
					room.addClass("show").addClass("open");
					var cont = room.find(".chat-room-chats-container");
					cont.find(".vote-box").remove();
					cont.append(UI.CreateNewGameChatBox(function(){
						Logic.ApiAccess.RemoveCurrentGame(data.id);
					}));
				}
				else {
					room.removeClass("show");
					if (!room.hasClass("chat-common"))
						room.addClass("over").removeClass("open");
					else room.addClass("c-over").addClass("open");
				}
			}
			thisref.LoopEvents.push(JSON.stringify({
				mode: "getGroup",
				group: thisref.id
			}));
		}
		lastGame = game;
	};
	
	var updateUserCalled = false;
	var updateUser = this.UpdateUser;
	this.UpdateUser = function(user) {
		updateUser(user);
		if (!updateUserCalled){
			updateUserCalled = true;
			for (var i = 0; i<user.length; ++i) {
				thisref.LoopEvents.push(JSON.stringify({
					mode: "getPlayer",
					game: data.currentGame.id,
					user: user[i],
					me: Data.UserId
				}));
			}
		}
	};
	
	var playerList = {};
	this.UpdatePlayer = function(player) {
		playerList[player.user] = player;
		var elem = this.content.find(".user-entry.entry-"+player.user)
			.find(".user-roles");
		for (var i = 0; i<player.roles.length; ++i) {
			var key = player.roles[i].roleKey;
			if (elem.find(".role-"+key).length == 0) {
				UI.CreateRole(key).appendTo(elem);
			}
		}
		if (!player.alive) {
			var key = "death";
			if (elem.find(".role-"+key).length == 0) {
				UI.CreateRole(key).appendTo(elem);
			}
		}
		if (player.user == Data.UserId) {
			var cont = thisref.content.find(".h-container-i");
			if (player.alive) cont.removeClass("death");
			else cont.addClass("death");
		}
	};
	
	this.UpdateRoom = function(room) {
		var cont = thisref.content.find(".h-container-i");
		for (var key in room) {
			if (!room.hasOwnProperty(key)) continue;
			if (rooms[key] == undefined) {
				rooms[key] = {
					id: key,
					last: 0,
					access: room[key],
					player: [],
					chats: [],
					box: UI.CreateChatBox(
						room[key].chatmode, key, function(){
							var key = $(this).attr("data-id");
							var ta = rooms[key].box.find("textarea");
							var text = ta.val();
							if (text!="") {
								Logic.ApiAccess.AddChat(key, Data.UserId, text);
							}
							ta.val("");
						}).appendTo(cont)
				};
				if (!room[key].enableWrite)
					rooms[key].box.addClass("readonly");
				Data.ChatRoomGames[key] = thisref;
				thisref.LoopEvents.push(JSON.stringify({
					mode: "getChatRoom",
					chat: key
				}));
				Logic.ApiAccess.GetPlayerInRoom(key);
			}
		}
	};
	this.OrderTabs = function() {
		var score = function(p) {
			var v = 0;
			v += (p.hasClass("open")          ? 1 : 0) * 16;
			v += (p.hasClass("chat-story")    ? 1 : 0) *  8;
			v += (p.hasClass("chat-common")   ? 0 : 1) *  4;
			v += (p.hasClass("chat-lovepair") ? 0 : 1) *  2;
			v += (p.hasClass("readonly")      ? 0 : 1) *  1;
			return v;
		};
		var cont = thisref.content.find(".h-container-i");
		childs = cont.children().sort(function(a, b) {
			return score($(b)) - score($(a));
		});
		childs.removeClass("show");
		childs.eq(0).addClass("show");
		childs.appendTo(cont);
		var logs = childs.find(".chat-room-chats");
		for (var i = 0; i<logs.length; ++i)
			logs[i].scrollTop = logs[i].scrollHeight;
	};
	this.UpdateRoomData = function(room) {
		//console.log(room);
		var old = rooms[room.id].data;
		rooms[room.id].data = room;
		//Game finished
		if (currentGame.finished != null) return;
		//open states
		var modified = false;
		if (room.opened) {
			if (!rooms[room.id].box.hasClass("open")) {
				rooms[room.id].box.addClass("open");
				modified = true;
			}
		}
		else {
			if (rooms[room.id].box.hasClass("open")) {
				rooms[room.id].box.removeClass("open");
				modified = true;
			}
		}
		if (modified) {
			thisref.OrderTabs();
		}
		//enableVotings
		if (Data.UserId == data.leader) {
			if (room.enableVoting)
				rooms[room.id].box.addClass("enable-poll");
			else rooms[room.id].box.removeClass("enable-poll");
		}
		else {
			if (room.enableVoting && room.chatMode != 'story' && room.voting != null)
				rooms[room.id].box.addClass("enable-poll");
			else rooms[room.id].box.removeClass("enable-poll");
		}
		//Votings
		if (room.chatMode != 'story') {
			if (data.leader == Data.UserId) {
				//no voting in this round exists
				if (room.voting == null && (old == null || old.voting != null)) {
					rooms[room.id].box.find(".vote-box").remove();
					rooms[room.id].box.find(".chat-room-chats-container")
						.append(UI.CreateVoteBoxStartVote(room.id, room.chatMode, function() {
							Logic.ApiAccess.CreateVoting(room.id, 0);
						}));
				}
				//voting exists but its over
				else if (room.voting != null && room.voting.voteEnd != null &&
				(old == null || old.voting == null || old.voting.voteEnd == null)) {
					rooms[room.id].box.find(".vote-box").remove();
					rooms[room.id].box.find(".chat-room-chats-container")
						.append(UI.CreateVoteOverBox());
				}
				//voting exists
				else if (room.voting != null && room.voting.voteEnd == null && 
				(old == null || old.voting == null)) {
					rooms[room.id].box.find(".vote-box").remove();
					rooms[room.id].box.find(".chat-room-chats-container")
						.append(UI.CreateVoteBoxEndVote(room.id, room.chatMode, function() {
							Logic.ApiAccess.EndVoting(room.id);
						}));
				}
			}
			else {
				//no voting in this round exists
				if (room.voting == null && (old == null || old.voting != null)) {
					rooms[room.id].box.find(".vote-box").remove();
				}
				//voting exists but its over
				else if (room.voting != null && room.voting.voteEnd != null &&
				(old == null || old.voting == null || old.voting.voteEnd == null)) {
					rooms[room.id].box.find(".vote-box").remove();
					rooms[room.id].box.find(".chat-room-chats-container")
						.append(UI.CreateVoteOverBox());
				}
				//voting exists
				else if (room.voting != null && (old == null || old.voting == null)) {
					Logic.ApiAccess.GetVoteFromPlayer(room.id, Data.UserId);
				}
			}
		}
		//Next round
		else if (data.leader == Data.UserId) {
			if (old == null || old.added == null) {
				room.added = true;
				if (old != null) old.added = true;
				rooms[room.id].box.find(".vote-box").remove();
				rooms[room.id].box.find(".chat-room-chats-container")
					.append(UI.CreateNextRoundBox(function() {
						Logic.ApiAccess.NextRound(currentGame.id);
					}));
			}
		}
	};
	this.ShowClientVoteBox = function(id, hasVote) {
		var cont = rooms[id].box.find(".chat-room-chats-container");
		if (cont.children().filter(".singleVote").length>0) {
			cont.find(".own-votes").remove();
		}
		else {
			var list = [];
			if (!hasVote) {
				for (var i = 0; i<thisref.userList.length; ++i) {
					if (thisref.userList[i] == data.leader) continue;
					if (!playerList[thisref.userList[i]].alive) continue;
					list[thisref.userList[i]] = Data.UserIdNameRef[this.userList[i]];
				}
			}
			else list = null;
			rooms[id].box.find(".chat-room-chats-container")
				.append(UI.CreateVoteBoxSingleVote(id, rooms[id].data.chatMode, 
				list, function(_id){
					Logic.ApiAccess.AddVote(id, Data.UserId, _id);
				}));
		}
	};
	this.UpdateRoomPlayer = function(room, player) {
		rooms[room].player = player;
		var box = rooms[room].box.find(".player-smal-box");
		rooms[room].box.attr("data-player-count", player.length);
		for (var i = 0; i<player.length; ++i) {
			var elem = box.find(".entry-"+player.user);
			if (elem.length == 0 && player[i].alive)
				box.append(UI.CreateSinglePlayerView(
					player[i].user, Data.UserIdNameRef[player[i].user]));
			if (elem.length > 0 && !player[i].alive)
				elem.remove();
		}
	};
	this.UpdateVotes = function(room, votes) {
		var bar = rooms[room].box.find(".cur-vote-bar").children().eq(0);
		var max = rooms[room].player.length-1;
		var stat = max <= 0 ? 100 : 100 * votes.length / max;
		bar.css("width", stat + "%");
	};
	this.HandleNewChat = function(room, chat) {
		if (chat.length == 0) return;
		var log = rooms[room].box.find(".chat-room-chats");
		var treshhold = 16; //16px extra
		var doscroll = log[0].scrollTop + log[0].clientHeight >= log[0].scrollHeight - treshhold;
		for (var i = 0; i<chat.length; ++i) {
			if (rooms[room].chats.includes(chat[i].id)) continue;
			rooms[room].chats.push(chat[i].id);
			if (rooms[room].last < chat[i].sendDate)
				rooms[room].last = chat[i].sendDate;
			var name =chat[i].user == 0 ? Lang.Get("roles", "log") :
				Data.UserIdNameRef[chat[i].user];
			var text = chat[i].user == 0 ? Lang.GetSys(chat[i].text) :
				chat[i].text;
			var entry = UI.CreateChatSingleEntry(name,
				new Date(chat[i].sendDate*1000).toLocaleString(), text
			);
			entry.appendTo(log);
		}
		if (rooms[room].chats.length > 50)
			rooms[room].chats.splice(0, rooms[room].chats.length-50);
		if (doscroll) {
			log[0].scrollTop = log[0].scrollHeight;
		}
	};
	this.LoopEvents.push(function() {
		var d = [];
		for (var key in rooms) {
			if (rooms.hasOwnProperty(key)) {
				d.push(JSON.stringify({
					mode: "getLastChat",
					chat: rooms[key].id,
					since: rooms[key].last
				}));
				if (rooms[key].data != null && rooms[key].data.voting != null)
					d.push(JSON.stringify({
						mode: "getVotesFromRoom",
						chat: rooms[key].id
					}));
			}
		}
		return d;
	});
	
	var frame = this.content.find(".game-frame");
	frame.children().remove();
	frame.append(UI.CreateChatBoxContainer());
	
	var remove = this.Remove;
	this.Remove = function() {
		remove();
		Data.RunningGames[data.currentGame.id] = undefined;
	};
};
WerWolf.PlayGame.prototype = Object.create(WerWolf.RunningGame.prototype);
