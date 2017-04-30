<?php

abstract class JsonExport {
	protected $jsonNames = array();
	
	private function getJson($value) {
		if ($value === null) return null;
		if (is_bool($value)) return $value;
		if (is_numeric($value)) return $value;
		if (is_string($value)) return $value;
		if ($value instanceof JsonExport)
			return $value->exportJson();
		if (is_array($value)){
			$list = array();
			foreach ($value as $k => $v)
			$list[$k] = $this->getJson($v);
			return $list;
		}
		return null;
	}
	
	public function exportJson() {
		$json = array();
		foreach ($this->jsonNames as $name)
			$json[$name] = $this->getJson($this->$name);
		return $json;
	}
}