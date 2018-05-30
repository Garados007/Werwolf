<?php

include_once __DIR__ . '/ApiBase.php';

class Maintenance extends ApiBase {
    public function doMaintenance() {
        return $this->wrapError($this->error(
            "maintenance",
            "server is in maintenance mode - retry later"
        ));
    }
}