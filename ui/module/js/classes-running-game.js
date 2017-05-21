WerWolf.RunningGame = function(id, data) {
	var thisref = this;
	WerWolf.Game.call(this, data.name, data.name, function(){
		thisref.Activate();
	});
	this.id = id;
	this.data = data;
	this.content = UI.CreateUserFrame();
	Data.CurrentGames[id] = this;
	
	this.LoopEvents = [];
	var intervall = setInterval(function(){
		if (thisref.LoopEvents.length > 0) {
			var d = [];
			for (var i = 0; i<thisref.LoopEvents.length; ++i) {
				if (thisref.LoopEvents[i] instanceof Function) {
					var res = thisref.LoopEvents[i]();
					if (Array.isArray(res))
						d = d.concat(res);
					else d.push(res);
				}
				else d.push(thisref.LoopEvents[i]);
			}
			Logic.ApiAccess.Multi(d);
		}
	}, 1000);
	
	var updateUserNames = function(data) {
		thisref.content.find(".user-entry.entry-"+data.user)
			.find(".user-name").text(data.name);
	};
	Logic.RequestEvents.getAccountName.add(updateUserNames);
	
	this.LoopEvents.push(JSON.stringify({
		mode: "setUserOnline",
		group: id,
		user: Data.UserId
	}));
	this.UpdateUserOnline = function(users) {
		var container = thisref.content.find(".user-list");
		var now = Date.now() / 1000;
		var nds = new Date(now * 1000).toDateString();
		for (var i = 0; i<users.length; ++i) {
			var entry = container.find(".entry-"+users[i].user);
			if (entry.length == 0) continue;
			entry = entry.find(".user-online");
			var date = new Date(users[i].lastOnline * 1000);
			var ods = date.toDateString();
			var dif = now - users[i].lastOnline;
			var text = "";
			if (users[i].lastOnline == 0) text = "?";
			else if (dif < 10) text = Lang.Get("lastOnlineTime", "online");
			else if (dif < 60) text = Lang.Get("lastOnlineTime", "recently");
			else if (dif < 300) text = Lang.Get("lastOnlineTime", "afewminutes");
			else if (nds == ods) text = date.toLocaleTimeString();
			else text = date.toLocaleDateString();
			entry.text(text);
			entry.attr("title", users[i].lastOnline == 0 ? '?' : date.toLocaleString());
		}
	};
	
	var remove = this.Remove;
	this.Remove = function() {
		clearInterval(intervall);
		Logic.RequestEvents.getAccountName.remove(updateUserNames);
		remove();
		Data.CurrentGames[id] = undefined;
	};
	
	this.userList = [];
	this.UpdateUser = function(user) {
		thisref.userList = user;
		thisref.content.find(".user-count").text(""+user.length);
		var container = thisref.content.find(".user-list");
		var request = [];
		for (var i = 0; i<user.length; ++i) {
			var entry = container.find(".entry-"+user[i]);
			if (entry.length == 0) {
				var roles = [];
				if (data.leader == user[i]) roles.push("leader");
				else roles.push("member");
				var name = Data.UserIdNameRef[user];
				entry = UI.CreateUserEntry(user[i], name, roles);
				entry.appendTo(container);
				if (name == undefined)
					request.push(JSON.stringify({
						mode: "getAccountName",
						user: user[i]
					}));
			}
		}
		if (request.length>0)
			Logic.ApiAccess.Multi(request);
		thisref.content.find(".user-frame .loading-frame").remove();
	};
};
WerWolf.RunningGame.prototype = Object.create(WerWolf.Game.prototype);
