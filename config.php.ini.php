<?php
$PHPVERSIONS  = array("5.6","7.4","8.1");
$PHPDIRECTORY = array("cli","fpm");
foreach($PHPVERSIONS as $PHPVERSION) {
	foreach($PHPDIRECTORY as $PHPDIR) {
		if( ! file_exists("/etc/php/$PHPVERSION/$PHPDIR/php.ini") ) continue;
		if( ! file_exists("/root/php/$PHPVERSION/$PHPDIR/php.ini") ) continue;
		echo "\n";
		echo "php/$PHPVERSION/$PHPDIR";
		$path = "/tmp/php/$PHPVERSION/$PHPDIR/";
		file_exists($path) || mkdir($path, 0777, true);
		copy("/root/php/$PHPVERSION/$PHPDIR/php.ini", "/tmp/php/$PHPVERSION/$PHPDIR/php.ini.tmp");
		$contentFile = file_get_contents("/tmp/php/$PHPVERSION/$PHPDIR/php.ini.tmp");
		// ---
		$contentFile = preg_replace('/([;][\s]*)*error_reporting\s*=\s*([& ~]+?E_[A-Z_]{3,25})+/i', 'error_reporting = E_ALL', $contentFile);
		$contentFile = preg_replace('/([;][\s]*)*display_errors\s*=\s*Off/i', 'display_errors = On', $contentFile);
		$contentFile = preg_replace('/([;][\s]*)*date.timezone\s*=\s*[\r\n]/i', 'date.timezone = Asia/Jakarta'."\r\n", $contentFile);
		$contentFile = preg_replace('/([;][\s]*)*expose_php\s*=\s*On/i', 'expose_php = Off', $contentFile);
		$contentFile = preg_replace('/([;][\s]*)*upload_max_filesize\s*=\s*[0-9]+M/i', 'upload_max_filesize = 50M', $contentFile);
		$contentFile = preg_replace('/([;][\s]*)*max_input_vars\s*=\s*[0-9]+/i', 'max_input_vars = 20000', $contentFile);
		$contentFile = preg_replace('/([;][\s]*)*post_max_size\s*=\s*[0-9]+M/i', 'post_max_size = 50M', $contentFile);
		//$contentFile = preg_replace('/([;][\s]*)*/i', '', $contentFile);
		if("$PHPDIR" == "fpm") {
			$contentFile = preg_replace('/([;][\s]*)*max_execution_time\s*=\s*[0-9]+/i', 'max_execution_time = 3000', $contentFile);
			$contentFile = preg_replace('/([;][\s]*)*default_socket_timeout\s*=\s*[0-9]+/i', 'default_socket_timeout = 6000', $contentFile);
			// ---
			$contentFile = preg_replace('/([;][\s]*)*memory_limit\s*=\s*[0-9]+M/i', 'memory_limit = 8191M', $contentFile);
			$contentFile = preg_replace('/([;][\s]*)*session.cookie_lifetime\s*=\s*[0-9]+/i', 'session.cookie_lifetime = 14400', $contentFile);
			$contentFile = preg_replace('/([;][\s]*)*session.gc_maxlifetime\s*=\s*[0-9]+/i', 'session.gc_maxlifetime = 14400', $contentFile);
			//$contentFile = preg_replace('/([;][\s]*)*/i', '', $contentFile);
			// ---
		}
		if( file_exists("/etc/php/$PHPVERSION/$PHPDIR/php.ini") )
			file_put_contents("/etc/php/$PHPVERSION/$PHPDIR/php.ini", $contentFile, LOCK_EX);
	}
}
