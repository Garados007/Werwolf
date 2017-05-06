var WerWolf = WerWolf || {};

WerWolf.Game = function(tabName, title, click) {
	var thisref = this;
	this.tab = UI.CreateTab(tabName, title, click);
	this.content = UI.CreateLoadingIndicator();
	
	this.Attach = function() {
		thisref.tab.appendTo($(".tab-container"));
	};
	
	this.Activate = function() {
		$(".tab-button.active").removeClass("active");
		thisref.tab.addClass("active");
		var parent = thisref.tab.parent();
		thisref.tab.insertBefore(parent.children().eq(0));
		$(".main-content").children().remove();
		thisref.content.appendTo($(".main-content"));
	};
	
	this.Remove = function() {
		thisref.tab.remove();
		thisref.content.remove();
		for (var i = 0; i<Data.Games.length; ++i)
			if (Data.Games[i] == thisref) {
				Data.Games.splice(i, 1);
				break;
			}
	};
	
	Data.Games.push(this);
};

WerWolf.AddGame = function() {
	var thisref = this;
	WerWolf.Game.call(this, "+", Lang.Get("newTabName"), function() {
		thisref.Activate();
	});
	
	var activate = this.Activate;
	this.Activate = function() {
		if (Data.NewGameTab != null) return;
		var game = new WerWolf.NewGame();
		game.Attach();
		game.Activate();
	};
};
WerWolf.AddGame.prototype = Object.create(WerWolf.Game.prototype);

WerWolf.NewGame = function() {
	var thisref = this;
	WerWolf.Game.call(this, Lang.Get("newGameTabName"), 
		Lang.Get("newTabName"), function() {
			thisref.Activate();
		});
	Data.NewGameTab = this;
	this.content = UI.CreateNewGameBox(function(){
		var name = thisref.content.find(".newGroupName").val();
		if (name == "") {
			alert(Lang.Get("insertNameMessage"));
			return;
		}
		Logic.ApiAccess.CreateGroup(name, Data.UserId);
	});
	var remove = this.Remove;
	this.Remove = function() {
		remove();
		Data.NewGameTab = null;
	};
};
WerWolf.NewGame.prototype = Object.create(WerWolf.Game.prototype);

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
		if (thisref.LoopEvents.length > 0)
			Logic.ApiAccess.Multi(thisref.LoopEvents);
	}, 1000);
	
	var updateUserNames = function(data) {
		thisref.content.find(".user-entry.entry-"+data.user)
			.find(".user-name").text(data.name);
	};
	Logic.RequestEvents.getAccountName.add(updateUserNames);
	
	var remove = this.Remove;
	this.Remove = function() {
		clearInterval(intervall);
		Logic.RequestEvents.getAccountName.remove(updateUserNames);
		remove();
		Data.CurrentGames[id] = undefined;
	};
	
};
WerWolf.RunningGame.prototype = Object.create(WerWolf.Game.prototype);

WerWolf.PrepairGame = function(id, data) {
	WerWolf.RunningGame.call(this, id, data);
	var thisref = this;
	//fallback
	if (data.currentGame != null) {
		thisref.Remove();
		return;
	}
	//normal
	this.LoopEvents.push(JSON.stringify({
		mode: "getUserFromGroup",
		group: this.id
	}));
	this.UpdateUser = function(user) {
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
WerWolf.PrepairGame.prototype = Object.create(WerWolf.RunningGame.prototype);

WerWolf.PlayGame = function(id, data) {
	WerWolf.RunningGame.call(this, id, data);
	var thisref = this;
};
WerWolf.PlayGame.prototype = Object.create(WerWolf.RunningGame.prototype);


