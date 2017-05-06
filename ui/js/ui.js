//component of the werwolf package
//require: jquery, toolkit, toolkit.view


var UI = new function() {
	var thisref = this;
	var v = ToolKit.View;
	
	
	this.CreateLoadingIndicator = function() {
		return v.CreateElementRaw({
			css: [ "loading-frame" ],
			content: '<div><div></div><div></div><div></div></div>'
		});
	};
	
	this.CreateTab = function(text, title, click) {
		return v.CreateButton(text, click, {
			css: [ "tab-button" ],
			title: title
		});
	};
	
	this.CreateNewGameBox = function(clickNewGroup, clickJoinGroup) {
		return v.CreateElementRaw({
			css: ["v-container"],
			children: [
				v.CreateElementRaw({
					css: ["new-game-box"],
					children: [
						v.CreateElement("h2", Lang.Get("createNewGameGroup")),
						v.CreateElementRaw({
							css: ["input-group"],
							children: [
								v.CreateElement("span", Lang.Get("newGroupName")),
								v.CreateInput("text", null, {
									css: ["newGroupName"],
									placeholder: Lang.Get("newGroupNameInputPlaceholder")
								})
							]
						}),
						v.CreateButton(Lang.Get("createNewGroup"), clickNewGroup)
					]
				}),
				v.CreateElementRaw({
					css: ["new-game-box"],
					children: [
						v.CreateElement("h2", Lang.Get("joinExistingGroup")),
						v.CreateElementRaw({
							css: ["input-group"],
							children: [
								v.CreateElement("span", Lang.Get("joinGroupKey")),
								v.CreateInput("text", null, {
									css: ["joinGroupKey"],
									placeholder: Lang.Get("joinGroupKeyInputPlaceholder")
								})
							]
						}),
						v.CreateButton(Lang.Get("joinGroup"), clickJoinGroup)
					]
				})
			]
		});
	};
	
	this.CreateUserFrame = function() {
		return v.CreateElementRaw({
			css: ["game-user-frame"],
			children: [
				v.CreateElementRaw({
					css: ["user-frame"],
					children: [
						v.CreateElementRaw({
							css: ["v-container", "user-list"]
						}),
						thisref.CreateLoadingIndicator()
					]
				}),
				v.CreateElementRaw({
					css: ["game-frame"],
					children: [
						thisref.CreateLoadingIndicator()
					]
				})
			]
		});
	};
	
	this.CreateUserEntry = function(id, name, roles) {
		var r = [];
		for (var i = 0; i<roles.length; ++i)
			r.push(v.CreateElementRaw({
				css: ["role-"+roles[i]],
				text: Lang.Get("roles", roles[i])
			}));
		return v.CreateElementRaw({
			css: ["user-entry", "entry-"+id],
			children: [
				v.CreateElementRaw({
					css: ["user-name"],
					text: name == null ? Lang.Get("loadingName") : name
				}),
				v.CreateElementRaw({
					css: ["user-roles"],
					children: r
				})
			]
		});
	};
};
