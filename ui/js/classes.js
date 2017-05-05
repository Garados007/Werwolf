var WerWolf = WerWolf || {};

WerWolf.Game = function(id, data) {
	var thisref = this;
	this.id = id;
	this.data = data
	this.tab = UI.CreateTab(Lang.Get("newTabName"));
	
	this.Attach = function() {
		thisref.tab.appendTo($(".tab-container"));
	};
	
	Data.Games.push(this);
};