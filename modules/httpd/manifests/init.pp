
class httpd {
	Class['iptables::webserver'] -> Class['httpd']

	package { 'httpd':
		ensure => installed
	}

	service { 'httpd':
		ensure => running,
		enable => true,
		hasstatus => true,
		hasrestart => true,
	}

	package { 'mod_ssl':
		ensure => installed
	}
}
