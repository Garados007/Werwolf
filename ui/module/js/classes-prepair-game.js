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
	
	this.UpdateGroupInfo = function(data) {
		if (data.currentGame != null) {
			thisref.Remove();
			var game = new WerWolf.PlayGame(data.id, data);
			game.Attach();
			game.Activate();
			setTimeout(function(){
				location.reload();
			}, 500);
		}
	};
	
	this.UpdateGameData = function(game) {
		//Do nothing
	};
	
	var frame = this.content.find(".game-frame");
	frame.children().remove();
	if (data.leader == Data.UserId) {
		frame.append(UI.CreateGamePreSettings(data.name, 
			data.enterKey, 0, function() {
				var roles = [];
				var inputs = thisref.content.find(".role-ammount");
				for (var i = 0; i<inputs.length; ++i) {
					var val = inputs.eq(i).val()*1;
					var key = inputs.eq(i).attr("data-role");
					if (key == 'storytel') continue; //implicit given
					for (var n = 0; n<val; ++n)
						roles.push(key);
				}
				Logic.ApiAccess.CreateGame(id, roles);
				thisref.Remove();
				var game = new WerWolf.PlayGame(data.id, data);
				game.Attach();
				game.Activate();
				setTimeout(function(){
					location.reload();
				}, 500);
			}));
	}
	else {
		frame.append(UI.CreateMemberWaitScreen());
		this.LoopEvents.push(JSON.stringify({
			mode: "getGroup",
			group: this.id
		}));
	}
};
WerWolf.PrepairGame.prototype = Object.create(WerWolf.RunningGame.prototype);
