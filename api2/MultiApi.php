<?php

include_once __DIR__ . '/ApiBase.php';
include_once __DIR__ . '/ControlApi.php';
include_once __DIR__ . '/ConvApi.php';
include_once __DIR__ . '/GetApi.php';
include_once __DIR__ . '/InfoApi.php';

class MultiApi extends ApiBase {
    public function multi() {
        if (($result = $this->getData(array(
            'tasks' => 'json'
        ))) !== true)
            return $this->wrapError($result);
        if (!is_array($this->formated['tasks']))
            return $this->wrapError($this->errorFormat('tasks is in wrong format'));
        $classes = array(
            'control' => new ControlApi(),
            'conv' => new ConvApi(),
            'get' => new GetApi(),
            'info' => new InfoApi()
        );
        $result = array();
        foreach ($this->formated['tasks'] as $task) {
            if (!isset($task['_class']))
                return $this->wrapError($this->errorMulti('class not defined in task'));
            if (!isset($task['_method']))
                return $this->wrapError($this->errorMulti('method not defined in task'));
            if (!isset($classes[$task['_class']]))
                return $this->wrapError($this->errorMulti('class '.$task['_class'].' does not exists'));
            $class = $classes[$task['_class']];
            if (!is_callable([$class, $task["_method"]]) || substr($task["_method"], 0, 1) == '_')
                return $this->wrapError($this->errorMulti('method '.$task['_method'].' is not callable'));
            $class->replaceData($task);
            $method = $task['_method'];
            $result[] = $class->$method();
        }
        return $this->wrapResult($result);
    }

    private function errorMulti($info) {
        return $this->error('multi', $info);
    }
}