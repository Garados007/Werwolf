<?php

class ApiBase {
    public $data = array();
    public $formated = null;
    protected $account = null;

    public function __construct() {
        global $_GET, $_POST;
        foreach ($_GET as $key => $value)
            if (substr($key, 0, 1) != '_')
                $this->data[$key] = $value;
        foreach ($_POST as $key => $value)
            $this->data[$key] = $value;
        header("Content-Type: text/json", true);
    }

    protected function getData(array $format) {
        $result = array();
        foreach ($format as $key => $type) {
            if (substr($key, 0, 1) == '?') {
                $key = substr($key, 1, strlen($key)-1);
                if (!isset($this->data[$key]))
                    continue;
            }
            elseif (!isset($this->data[$key]))
                return $this->errorFormat("Key $key not given");
            switch ($type) {
                case "int":
                    $result[$key] = intval($this->data[$key]);
                    break;
                case "num":
                    $result[$key] = floatval($this->data[$key]);
                    break;
                case "bool":
                    $result[$key] = filter_var($this->data[$key], 
                        FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
                    if ($result[$key] === null) $result[$key] = false;
                    break;
                case "json":
                    $result[$key] = json_decode($this->data[$key], true);
                    if (json_last_error() != JSON_ERROR_NONE)
                        return $this->errorFormat("Key $key: ".
                            json_last_error_msg());
                    break;
                default:
                    $result[$key] = $this->data[$key];
            }
            if (is_array($type) && count($type) > 1)
                switch ($type[0]) {
                    case "regex":
                        if (!preg_match($type[1], $this->data[$key]))
                            return $this->errorFormat(
                                "Key $key: value doesn't match ".
                                $type[1]
                            );
                        break;
                }
        }
        if (isset($this->data['token']))
            $result['token'] = $this->data['token'];
        $this->formated = $result;
        return true;
    }

    protected function wrapResult($result) {
        global $_GET, $_POST;
        return array(
            "class" => $_GET["_class"],
            "method" => $_GET["_method"],
            "request" => $this->formated == null ?
                $this->data : $this->formated,
            "result" => $result instanceof JsonExport ?
                $result->exportJson() : $result
        );
    }

    protected function wrapError($error) {
        global $_GET, $_POST;
        return array(
            "class" => $_GET["_class"],
            "method" => $_GET["_method"],
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
        if ($this->account !== null) return;
        include_once __DIR__ . '/../account/manager.php';
        $this->account = AccountManager::GetCurrentAccountData();
        if ($this->account['login']) {
            $this->inclDb('UserStats');
            $user = UserStats::create($this->account['id']);
            if ($user === null)
                $user = UserStats::createNewUserStats($this->account['id']);
            $user->setOnline();
            return true;
        }
        else return $this->error('account', 'login required');
    }
}