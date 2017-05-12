var Lang = Lang || {};

Lang.GetSys = function(code) {
	code = JSON.parse(code);
	var result = "";
	var raw = Lang.Get("systemText", code.tid);
	for (var i = 0; i<raw.length; ++i) {
		var part = raw[i];
		if (part.t != undefined) {
			result += part.t;
		}
		else if (part.v != undefined) {
			result += code.var[part.v];
		}
		else if (part.pid2s != undefined) {
			result += Data.UserIdNameRef[code.var[part.pid2s]];
		}
	}
	return result;
};