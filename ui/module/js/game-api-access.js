var Logic = Logic || {};

Logic.ApiAccess = {
	Multi: function(requests) {
		var tasks = [];
		for (var i = 0; i<requests.length; ++i)
			tasks.push(JSON.stringify(requests[i]));
		if (tasks.length == 0) return;
		thisref.SendApiRequest({
			mode: "multi",
			"tasks[]": tasks
		});
	},
	GetAccountState: function() {
		thisref.SendApiRequest({
			mode: "getAccountState"
		});
	},
	GetAccountName: function(user) {
		thisref.SendApiRequest({
			mode: "getAccountName",
			user: user
		});
	},
	CreateGroup: function(name, user) {
		thisref.SendApiRequest({
			mode: "createGroup",
			name: name,
			user: user
		});
	},
	GetGroup: function(id) {
		thisref.SendApiRequest({
			mode: "getGroup",
			group: id
		});
	},
	AddUserToGroupByKey: function(user, key) {
		thisref.SendApiRequest({
			mode: "addUserToGroupByKey",
			user: user,
			key: key
		});
	},
	GetGroupsFromUser: function(user) {
		thisref.SendApiRequest({
			mode: "getGroupFromUser",
			user: user
		});
	},
	RemoveCurrentGame: function(group) {
		thisref.SendApiRequest({
			mode: "removeCurrentGame",
			group: group
		});
	},
	CreateGame: function(group, roles) {
		thisref.ApiAccess.Multi([JSON.stringify({
			mode: "createGame",
			group: group,
			roles: roles
		})]);
	},
	NextRound: function(game) {
		thisref.SendApiRequest({
			mode: "nextRound",
			game: game
		});
	},
	GetPlayerInRoom: function(chat) {
		thisref.SendApiRequest({
			mode: "getPlayerInRoom",
			chat: chat,
			me: Data.UserId
		});
	},
	AddChat: function(chat, user, text) {
		thisref.SendApiRequest({
			mode: "addChat",
			chat: chat,
			user: user,
			text: text
		});
	},
	CreateVoting: function(chat, end) {
		thisref.SendApiRequest({
			mode: "createVoting",
			chat: chat,
			end: end == null ? 0 : end
		});
	},
	EndVoting: function(chat) {
		thisref.SendApiRequest({
			mode: "endVoting",
			chat: chat
		});
	},
	AddVote: function(chat, user, target) {
		thisref.SendApiRequest({
			mode: "addVote",
			chat: chat,
			user: user,
			target: target
		});
	},
	GetVoteFromPlayer: function(chat, user) {
		thisref.SendApiRequest({
			mode: "getVoteFromPlayer",
			chat: chat,
			user: user
		});
	}
};