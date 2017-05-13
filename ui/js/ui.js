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
				})
			]
		});
	};
	
	this.CreateRole = function(role) {
		return v.CreateElementRaw({
			css: ["role-"+role],
			text: Lang.Get("roles", role)
		});
	};
	
	this.CreateUserEntry = function(id, name, roles) {
		var r = [];
		for (var i = 0; i<roles.length; ++i)
			r.push(thisref.CreateRole(roles[i]));
		return v.CreateElementRaw({
			css: id == Data.UserId ?
				["user-entry", "entry-"+id, "current"] :
				["user-entry", "entry-"+id],
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
						readonly: "true",
						"data-role": key
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
						pattern: "\d+",
						"data-role": key
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
	
	this.CreateChatBoxContainer = function() {
		return v.CreateElementRaw({
			css: ["h-container"],
			children: [
				v.CreateElementRaw({
					css: ["h-container-i"]
				})
			]
		});
	};
	
	this.CreateChatBoxHeader = function(name, clickUser, clickPoll, clickTitle) {
		return v.CreateElementRaw({
			css: ["chat-room-header"],
			children: [
				v.CreateButton("", clickUser, {
					children: [
						v.CreateElementRaw({
							element: "img",
							src: "/"+$WWV.urlBase+"ui/img/Users-Group-icon.png"
						})
					]
				}),
				v.CreateButton("", clickTitle, {
					text: Lang.Get("chats", name)
				}),
				v.CreateButton("", clickPoll, {
					children: [
						v.CreateElementRaw({
							element: "img",
							src: "/"+$WWV.urlBase+"ui/img/Messaging-Poll-Topic-icon.png"
						})
					]
				})
			]
		});
	};
	
	this.CreateChatBoxTextBox = function(id, clickSend) {
		var textarea = v.CreateElementRaw({
			element: "textarea",
			css: ["chat-room-text"]
		});
		var button = v.CreateButton("", clickSend, {
			"data-id": id,
			children: [
				v.CreateElementRaw({
					element: "img",
					src: "/"+$WWV.urlBase+"ui/img/Mail-Send-icon.png"
				})
			]
		});
		textarea.keydown(function (e) {
			if (e.keyCode == 13 && !e.ctrlKey && !e.shiftKey) {
				clickSend.call(button);
			}
		});
		textarea.keyup(function(e) {
			if (e.keyCode == 13 && !e.ctrlKey && !e.shiftKey) {
				$(this).val("");
			}
		});
		return v.CreateElementRaw({
			css: ["chat-room-textbox"],
			children: [ textarea, button ]
		});
	};
	
	this.CreateChatBox = function(name, id, clickSend) {
		var e = v.CreateElementRaw({
			css: ["chat-room-box", "room-"+id, "chat-"+name],
			children: [
				v.CreateElementRaw({
					children: [
						v.CreateElementRaw({
							children: [
								thisref.CreateChatBoxHeader(name, function() {
									
								}, function() {
									e.toggleClass("view-poll");
								}, function() {
									if (e.parent().hasClass("list")) {
										e.parent().children().removeClass("show");
										e.addClass("show");
									}
									e.parent().toggleClass("list");
								})
							]
						})
					]
				}),
				v.CreateElementRaw({
					children: [
						v.CreateElementRaw({
							children: [
								thisref.CreateChatBoxChatList()
							]
						})
					]
				}),
				v.CreateElementRaw({
					children: [
						v.CreateElementRaw({
							children: [
								thisref.CreateChatBoxTextBox(id, clickSend)
							]
						})
					]
				})
			]
		});
		return e;
	};
	
	this.CreateChatBoxChatList = function() {
		return v.CreateElementRaw({
			css: ["chat-room-chats-container"],
			children: [
				v.CreateElementRaw({
					css: ["chat-room-chats", "v-container"]
				}),
			]
		});
	};
	
	this.CreateChatSingleEntry = function(sender, date, message) {
		return v.CreateElementRaw({
			css: ["chat-single-entry"],
			children: [
				v.CreateElementRaw({
					css: ["chat-single-entry-header"],
					children: [
						v.CreateElementRaw({
							css: ["chat-single-entry-name"],
							text: sender
						}),
						v.CreateElementRaw({
							css: ["chat-single-entry-date"],
							text: date
						})
					]
				}),
				v.CreateElementRaw({
					css: ["chat-single-entry-text"],
					text: message
				})
			]
		});
	};
	
	this.CreateVoteBoxStartVote = function(id, name, clickStart) {
		return v.CreateElementRaw({
			css: ["vote-box", "startVote", "v-container"],
			children: [
				v.CreateElementRaw({
					text: Lang.Get("voteDesc", name)
				}),
				v.CreateButton(Lang.Get("startVotingButton"), clickStart)
			]
		});
	};
	
	this.CreateVoteBoxEndVote = function(id, name, clickEnd) {
		return v.CreateElementRaw({
			css: ["vote-box", "endVote", "v-container"],
			children: [
				v.CreateElementRaw({
					text: Lang.Get("voteDesc", name)
				}),
				v.CreateElementRaw({
					text: Lang.Get("currentVoted")
				}),
				v.CreateElementRaw({
					css: ["cur-vote-bar"],
					children: [
						v.CreateElementRaw({
							style: 'width: 0%'
						})
					]
				}),
				v.CreateButton(Lang.Get("endVotingButton"), clickEnd)
			]
		});
	};
	
	this.CreateVoteOverBox = function() {
		return v.CreateElementRaw({
			css: ["vote-box", "voteOver", "v-container"],
			children: [
				v.CreateElementRaw({
					text: Lang.Get("voteOver")
				})
			]
		});
	};
	
	this.CreateNewGameBox = function(clickNew) {
		return v.CreateElementRaw({
			css: ["vote-box", "finish", "v-container"],
			children: [
				v.CreateButton(Lang.Get("createNewGame"), clickNew)
			]
		});
	};
	
	this.CreateVoteBoxSingleVote = function(id, name, user, clickId) {
		var votes = [];
		if (user != null) {
			votes.push(v.CreateElementRaw({
				text: Lang.Get("yourVote")
			}));
			for (var key in user)
				if (user.hasOwnProperty(key))
					votes.push(v.CreateButton(user[key], function(){
						if (clickId) clickId($(this).attr("data-id"));
					}, {
						"data-id": key
					}));
		}
		return v.CreateElementRaw({
			css: ["vote-box", "singleVote", "v-container"],
			children: [
				v.CreateElementRaw({
					text: Lang.Get("voteDesc", name)
				}),
				v.CreateElementRaw({
					text: Lang.Get("currentVoted")
				}),
				v.CreateElementRaw({
					css: ["cur-vote-bar"],
					children: [
						v.CreateElementRaw({
							style: 'width: 0%'
						})
					]
				}),
				v.CreateElementRaw({
					css: ["own-votes"],
					children: votes
				})
			]
		});
	};
	
	this.CreateNextRoundBox = function(clickNext) {
		return v.CreateElementRaw({
			css: ["round-box", "vote-box", "v-container"],
			children: [
				v.CreateButton(Lang.Get("nextRound"), clickNext)
			]
		});
	};
};
