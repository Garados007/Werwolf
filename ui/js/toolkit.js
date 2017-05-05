
var ToolKit = ToolKit || {};

ToolKit.Event = function() {
	var thisref = this;
	var list = [];
	//Fügt eine neue Eventmethode zu diesem Event hinzu.
	//method: function - die Methode, die beim Auslösen des Events aufgerufen wird.
	this.add = function(method) {
		if (method == undefined) throw new Error("no method given");
		for (var i = 0; i<list.length; ++i)
			if (list[i] == method) return;
		list.push(method);
	};
	//Entfernt eine Eventmethode wieder
	//method: function - die Methode, die nicht mehr aufgerufen werden soll.
	this.remove = function(method) {
		for (var i = 0; i<list.length; ++i)
			if (list[i] == method) {
				list.splice(i, 1);
				return;
			}
	};
	//Ruft alle Methoden mit aktuellen Kontext und verschiedenen Argumenten auf.
	//args: Werte... - Verschiedene Argumente
	this.invoke = function(args) {
		for (var i = 0; i<list.length; ++i)
			list[i].apply(this, arguments);
	};
	//Ruft alle Methoden in einem bestimmten Kontext und verschiedenen Argumenten auf.
	//thisArg: Wert     - der Zielkontext für die Methoden
	//args:    Werte... - Verschiedene Argumente
	this.call = function(thisArg, args) {
		arguments.splice(0, 1);
		for (var i = 0; i<list.length; ++i)
			list[i].apply(thisArg, arguments);
	};
	//Fügt eine neue Eventmethode zu diesem Event hinzu. Diese 
	//wird höchstens einmal aufgerufen und gleich danach wieder
	//entfernt.
	//method: function - die Methode, die beim Auslösen des Events aufgerufen wird.
	this.addSingle = function(method) {
		var handler = function() {
			thisref.remove(handler);
			method.apply(this, arguments);
		};
		list.push(handler);
	};
};
//Implementiert eine einfache Queue
ToolKit.Queue = function() {
	var first = null, last = null, count = 0;
	//Legt ein Element an das Ende der Queue
	//element: Wert - das neue Element
	this.push = function(element) {
		var entry = {
			element: element,
			prev: last
		};
		if (last == null) first = last = entry;
		else {
			last.next = entry;
			last = entry;
		}
		count++;
	};
	//Ruft das erste Element von der Queue ab und entfernt dieses
	//return: Wert - der erste Eintrag
	this.pop = function() {
		if (first == null) return null;
		var element = first.element;
		if (first.next) first = first.next;
		else first = last = null;
		count--;
		return element;
	};
	//Fragt ab, ob diese Queue leer ist.
	//return: Bool - true wenn Queue leer
	this.isEmpty = function() {
		return first == null;
	};
	//Ruft das erste Element von der Queue ab ohne es zu entfernen
	//return: Wert - der erste Eintrag
	this.pick = function() {
		if (first == null) return null;
		else return first.element;
	};
	//Löscht alle Elemente in der Queue
	this.clear = function() {
		first = last = null;
		count = 0;
	};
	//Ermittelt die Anzahl in der Queue
	this.size = function() {
		return count;
	};
};

