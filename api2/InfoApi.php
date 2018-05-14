<?php 

include_once __DIR__ . '/ApiBase.php';

class InfoApi extends ApiBase {
    public function installedGameTypes() {
        if (($result = $this->getData(array(
        ))) !== true)
            return $this->wrapError($result);
        $this->inclRolH();
        return $this->wrapResult(RoleHandler::getAllModes());
    }

    public function createOptions() {
        if (($result = $this->getData(array(
            'type' => [ 'regex', '/[a-zA-Z0-9_\-]+/' ]
        ))) !== true)
            return $this->wrapError($result);
        $this->inclRolH();
        if (!in_array(
            $this->formated['type'],
            RoleHandler::getAllModes()
        )) $this->wrapError($this->errorId('type not found'));
        $conf = json_decode(file_get_contents(
            __DIR__.'/../logic/Role/'.$this->formated['type']
            .'/varinfo.json'
        ), true);
        if (json_last_error() !== JSON_ERROR_NONE)
            return $this->wrapError($this->errorFormat(
                'parse error:'.json_last_error_msg()
            ));
        return $this->wrapResult($conf);
    }

    public function installedRoles() {
        if (($result = $this->getData(array(
            'type' => [ 'regex', '/[a-zA-Z0-9_\-]+/' ]
        ))) !== true)
            return $this->wrapError($result);
        $this->inclRolH();
        if (!RoleHandler::loadAllRoles($this->formated['type']))
            return $this->wrapError($this->errorId(
                'type not found'
            ));
        return $this->wrapResult(RoleHandler::getRoles(
            $this->formated['type']
        ));
    }

    public function rolesets() {
        if (($result = $this->getData(array(
            'type' => [ 'regex', '/[a-zA-Z0-9_\-]+/' ]
        ))) !== true)
            return $this->wrapError($result);
        $this->inclRolH();
        if (($conf = ROleHandler::loadConfig(
            $this->formated['type']
        )) === false) return $this->wrapError(
            $this->errorId('type not found')
        );
        $result = array();
        foreach ($conf->rolesets as $set)
            $result[] = $set->key;
        return $this->wrapResult($result);
    }
}