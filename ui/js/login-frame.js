$(function(){
	$(".start-button").click(function() {
		$(".overlay").addClass("open");
		$(".login-window")[0].src =
			'/'+$WWV.urlBase+'account/login/';
	});
	$(".close-button").click(function() {
		$(".overlay").removeClass("open");
	});
	var frame = $(".login-window");
	$("iframe").on('load', function() {
		var loc = $(".login-window")[0].contentWindow.location.href;
		var expected = $WWV.urlHost+$WWV.urlBase+'account/checked/';
		if (loc == expected) {
			$(".overlay").removeClass("open");
			$.get(expected, "", function(data) {
				if (data.login) {
					document.location.href = $WWV.urlHost+$WWV.urlBase+
						'ui/game/';
				}
			});
		}
	});
});