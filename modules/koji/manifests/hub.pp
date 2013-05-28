
class koji::hub($auth, $db, $web, $realm = 'NONE') {
	# Require the Apache and mod_ssl packages.
	# For some reason, when I do this, I can't notify => Service['httpd'].
	# Puppet complains about cyclical deps.
	#Class['httpd'] -> Class['koji::hub']

	package { 'koji-hub': ensure => installed }
	
	file { '/etc/httpd/conf.d/packages.conf':
		content => template('koji/hub/packages.conf.erb'),
		notify => Service['httpd'],
		require => Package['httpd'],
	}


	file { '/etc/httpd/conf.d/ssl.conf':
		content => template('koji/hub/ssl.conf.erb'),
		notify => Service['httpd'],
		require => [
			Package['mod_ssl'],
			File[ "/etc/pki/tls/private/${::fqdn}.key"],
			File[ "/etc/pki/tls/certs/${::fqdn}.crt"]
		],
	}

	file { '/etc/koji-hub/hub.conf':
		content => template('koji/hub/hub.conf.erb'),
		notify => Service['httpd'],
		require => Package['koji-hub'],
	}


	# Lock down the SSL private key
	file { "/etc/pki/tls/private/${::fqdn}.key":
		ensure => present, # sanity check
		owner => root, group => root,
		mode => 600,
		source => "puppet:///modules/koji/ssl/${::fqdn}.key",
	}
	file { "/etc/pki/tls/certs/${::fqdn}.crt":
		ensure => present, # sanity check
		owner => root, group => root,
		mode => 644,
		source => "puppet:///modules/koji/ssl/${::fqdn}.crt",
	}
	# Apache must be able to connect to Postgres
	selboolean { 'httpd_can_network_connect_db':
		persistent => true,
		value => on,
	}

	# Filesystem skeleton
	file { '/mnt/koji':
		ensure => directory,
		require => Package['httpd'],
	}
	file { [
		'/mnt/koji/packages',
		'/mnt/koji/repos',
		'/mnt/koji/work',
		'/mnt/koji/scratch',
	]:
		ensure => directory,
		owner => 'apache', group => 'apache',
		require => File['/mnt/koji'],
	}

	case $auth {
		kerberos: { fail('SSL auth not yet implemented.') }
		ssl: { fail('SSL auth not yet implemented.') }
		default: { fail('Unrecognized auth type for DB.') }
	}
}

class koji::hub::kerberos {
	file { '/etc/koji-hub/hub.keytab':
		ensure => present,
		source => '/etc/krb5.keytab',
		owner => 'root', group => 'apache',
		mode => '640',
		notify => Service['httpd'],
		require => Package['koji-hub'],
	}
}

class koji::hub::ssl {
	file { '/etc/koji-hub':
		ensure => present,
		require => Package['koji-hub'],
	}
}
