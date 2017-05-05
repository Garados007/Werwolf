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
	
	this.CreateTab = function(text) {
		return v.CreateButton(text, undefined, {
			css: [ "tab-button" ],
			children: [
				v.CreateButton('x')
			]
		});
	}
};
