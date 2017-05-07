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
	
	this.CreateGamePreSettings = function(name, gameKey, userCount, clickStart) {
		var list = [];
		var used;
		for (var i = 0; i<Const.RoleKeys.length; ++i) {
			var key = Const.RoleKeys[i];
			//eliminate unwanted keys (they are implicit given)
			if (key == 'log' || key == 'major' || key == 'pair' || key == 'villager') continue;
			list.push(v.CreateElementRaw({
				css: ["role-setting"],
				children: [
					v.CreateElement("div", Lang.Get("roles", key)),
					key == "storytel" ?
					v.CreateInput("number", null, {
						css: ["role-ammount", "role-ammount-"+key],
						value: 1,
						readonly: "true"
					}) :
					v.CreateInput("number", function() {
						this.value = this.value.replace(/[^0-9]/g, '');
						if (this.value == '') this.value = 0;
						var inputs = $(this).parent().parent().find("input");
						var sum = 0;
						for (var i = 0; i<inputs.length; ++i)
							sum += inputs[i].value * 1;
						used.text(sum);
					}, {
						css: ["role-ammount", "role-ammount-"+key],
						min: 0,
						step: 1,
						value: 0,
						pattern: "\d+"
					})
				]
			}));
		}
		list.push(v.CreateElementRaw({
			css: ["role-setting", "inliner"],
			children: [
				v.CreateElement("div", ""),
				v.CreateElementRaw({
					children: [
						used = v.CreateElementRaw({
							text: "1"
						}),
						v.CreateElementRaw({
							text: "/"
						}),
						v.CreateElementRaw({
							css: ["user-count"],
							text: ""+userCount
						})
					]
				})
			]
		}));
		console.log(userCount);
		return v.CreateElementRaw({
			css: ["v-container"],
			children: [
				v.CreateElementRaw({
					css: ["new-game-box"],
					children: [
						v.CreateElement("h2", name),
						v.CreateElementRaw({
							css: ["input-group"],
							children: [
								v.CreateElement("span", Lang.Get("inviteKeyDescription")),
								v.CreateInput("text", null, {
									css: ["joinGroupKey"],
									placeholder: gameKey,
									value: gameKey,
									readonly: "true"
								})
							]
						})
					]
				}),
				v.CreateElementRaw({
					css: ["new-game-box"],
					children: [
						v.CreateElement("h2", Lang.Get("startNewGame")),
						v.CreateElementRaw({
							css: ["input-group"],
							children: [
								v.CreateElement("span", Lang.Get("setRolesDescription")),
								v.CreateElementRaw({
									css: ["role-table"],
									children: list
								})
							]
						}),
						v.CreateButton(Lang.Get("startGame"), clickStart)
					]
				})
			]
		});
	};
	
	this.CreateMemberWaitScreen = function() {
		return v.CreateElementRaw({
			css: ["v-container"],
			children: [
				v.CreateElementRaw({
					css: ["new-game-box"],
					children: [
						v.CreateElement("h2", Lang.Get("memberWaitTitle")),
						v.CreateElementRaw({
							text: Lang.Get("memberWaitDescription")
						})
					]
				})
			]
		});
	};
};
