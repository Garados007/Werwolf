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
	}
	return result;
};