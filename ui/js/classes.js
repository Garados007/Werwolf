var WerWolf = WerWolf || {};

WerWolf.Game = function(tabName, title, click) {
	var thisref = this;
	this.tab = UI.CreateTab(tabName, title, click);
	
	this.Attach = function() {
		thisref.tab.appendTo($(".tab-container"));
	};
	
	this.Activate = function() {
		$(".tab-button.active").removeClass("active");
		thisref.tab.addClass("active");
		var parent = thisref.tab.parent();
		thisref.tab.insertBefore(parent.children().eq(0));
	}
	
	Data.Games.push(this);
};

WerWolf.AddGame = function() {
	var thisref = this;
	WerWolf.Game.call(this, "+", Lang.Get("newTabName"), function() {
		thisref.Activate();
	});
	
	var activate = this.Activate;
	this.Activate = function() {
		var game = new WerWolf.NewGame();
		game.Attach();
		game.Activate();
	};
};
WerWolf.AddGame.prototype = Object.create(WerWolf.Game.prototype);

WerWolf.NewGame = function() {
	WerWolf.Game.call(this, Lang.Get("newGameTabName"), Lang.Get("newTabName"));
	var thisref = this;
	
};
WerWolf.NewGame.prototype = Object.create(WerWolf.Game.prototype);

WerWolf.RunningGame = function(id, data) {
	WerWolf.Game.call(this, Lang.Get("newTabName"), Lang.Get("newTabName"));
	var thisref = this;
	this.data = data;
};
WerWolf.RunningGame.prototype = Object.create(WerWolf.Game.prototype);
