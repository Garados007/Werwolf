<?php

class ApiBase {
    public $data = array();
    public $formated = null;
    protected $account = null;
    private $class, $method;

    public function __construct() {
        global $_GET, $_POST;
        foreach ($_GET as $key => $value)
            if (substr($key, 0, 1) != '_')
                $this->data[$key] = $value;
        foreach ($_POST as $key => $value)
            $this->data[$key] = $value;
        $this->class = $_GET['_class'];
        $this->method = $_GET['_method'];
        header("Content-Type: text/json", true);
    }

    protected function replaceData($data) {
        $this->data = array();
        foreach ($data as $key => $value)
            if (substr($key, 0, 1) != '_')
                $this->data[$key] = $value;
        $this->class = $data['_class'];
        $this->method = $data['_method'];
    }

    protected function getData(array $format) {
        $result = $this->getDataInner($format, $this->data);
        if (isset($result['error']))
            return $result['error'];
        $this->formated = $result['result'];
        return true;
    }

    private function getDataInner(array $format, $data) {
        $result = array();
        foreach ($format as $key => $type) {
            if (substr($key, 0, 1) == '?') {
                $key = substr($key, 1, strlen($key)-1);
                if (!isset($data[$key]))
                    continue;
            }
            elseif (!isset($data[$key]))
                return array(
                    'error' => $this->errorFormat("Key $key not given")
                );
            switch ($type) {
                case "int":
                    $result[$key] = intval($data[$key]);
                    break;
                case "num":
                    $result[$key] = floatval($data[$key]);
                    break;
                case "bool":
                    $result[$key] = filter_var($data[$key], 
                        FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
                    if ($result[$key] === null) $result[$key] = false;
                    break;
                case "string":
                    if (is_array($data[$key]))
                        return array(
                            'error' => $this->errorFormat(
                                "Key $key: is an array instead of string"
                            )
                        );
                    $result[$key] = strval($data[$key]);
                    break;
                case "json":
                    if (is_string($data[$key])) {
                        $result[$key] = json_decode($data[$key], true);
                        if (json_last_error() != JSON_ERROR_NONE)
                            return array(
                                'error' => $this->errorFormat("Key $key: ".
                                    json_last_error_msg()
                                )
                            );
                    }
                    elseif (is_array($data[$key])) {
                        $result[$key] = $data[$key];
                    }
                    else
                        return array(
                            'error' => $this->errorFormat(
                                "Key $key: is not valid json"
                            )
                        );
                    break;
                default:
                    $result[$key] = $data[$key];
            }
            if (is_array($type) && count($type) > 1)
                switch ($type[0]) {
                    case "regex":
                        if (!is_string($data[$key]))
                            return array(
                                'error' => $this->errorFormat(
                                    "Key $key: value is not a string"
                                )
                            );
                        if (!preg_match($type[1], $data[$key]))
                            return array(
                                'error' => $this->errorFormat(
                                    "Key $key: value doesn't match ".
                                    $type[1]
                                )
                            );
                        break;
                    case "list":
                        $form = array();
                        foreach ($data[$key] as $k => $v)
                            $form[$k] = $type[1];
                        $lr = $this->getDataInner($form, $data[$key]);
                        if (isset($lr['error']))
                            return array(
                                'error' => $this->errorFormat(
                                    "Key $key: ".$lr['error']['info']
                                )
                            );
                        $result[$key] = $lr['result'];
                        break;
                    case "object":
                        $lr = $this->getDataInner($type[1], $data[$key]);
                        if (isset($lr['error']))
                            return array(
                                'error' => $this->errorFormat(
                                    "Key $key: ".$lr['error']['info']
                                )
                            );
                        $result[$key] = $lr['result'];
                    break;
                }
        }
        if (isset($data['token']))
            $result['token'] = $data['token'];
        return array(
            'result' => $result
        );
    }

    protected function setValues($keys, $target) {
        foreach ($keys as $key)
            if (isset($this->formated[$key]))
                $target->$key = $this->formated[$key];
    }

    protected function wrapResult($result) {
        global $_GET, $_POST;
        return array(
            "class" => $this->class,
            "method" => $this->method,
            "request" => $this->formated == null ?
                $this->data : $this->formated,
            "result" => $result instanceof JsonExport ?
                $result->exportJson() : $result
        );
    }

    protected function wrapError($error) {
        global $_GET, $_POST;
        return array(
            "class" => $this->class,
            "method" => $this->method,
            "request" => $this->formated == null ?
                $this->data : $this->formated,
            "error" => $error
        );
    }

    protected function error($key, $info) {
        return array(
            "key" => $key,
            "info" => $info
        );
    }

    protected function errorFormat($info) {
        return self::error("format", $info);
    }

    protected function errorId($info) {
        return self::error("wrongId", $info);
    }

    protected function inclDb(...$name) {
        foreach ($name as $n)
            include_once __DIR__ . "/../db/$n/$n.php";
    }

    protected function inclPerm() {
        include_once __DIR__ . '/../logic/Permission/Permission.php';
    }

    protected function inclRolH() {
        include_once __DIR__ . '/../logic/Role/RoleHandler.php';
    }

    protected function getAccount() {
        if ($this->account === null) {
            include_once __DIR__ . '/../account/manager.php';
            $this->account = AccountManager::GetCurrentAccountData();
            $fetch = true;
        }
        else $fetch = false;
        if ($this->account['login']) {
            if ($fetch) {
                $this->inclDb('UserStats');
                $user = UserStats::create($this->account['id']);
                if ($user === null)
                    $user = UserStats::createNewUserStats($this->account['id']);
                $user->setOnline();
            }
            return true;
        }
        else return $this->error('account', 'login required');
    }

    ////copied from other project - needs to be tested
    // protected function init($data, $permission, $db) {
    //     if (($result = $this->getData($data)) !== true)
    //         return $this->wrapError($result);
    //     $this->inclPerm();
    //     $ap = new ApiPermission();
    //     foreach ($permission as $key => $perm) {
    //         if (substr($key, 0, 1) == '?') {
    //             $key = substr($key, 1, strlen($key)-1);
    //             $break = false;
    //             foreach ($perm as $p)
    //                 if (!isset($this->formated[$p])) {
    //                     $break = true;
    //                     break;
    //                 }
    //             if ($break) continue;
    //         }
    //         $name = 'canAccess' . $key;
    //         if (!call_user_func_array(array($ap, $name), array_merge(
    //             array($this->account['id']),
    //             array_map(
    //                 function ($element) {
    //                     return $this->formated[$element];
    //                 },
    //                 $perm
    //             )
    //         )))
    //             return $this->wrapError($this->errorAccess());
    //     }
    //     call_user_func_array(array($this, "inclDb"), $db);
    //     return null;
    // }
}