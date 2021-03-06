
class koji::web($auth, $hub, $realm = 'NONE') {
	# Require the Apache and mod_ssl packages.
	# For some reason, when I do this, I can't notify => Service['httpd'].
	# Puppet complains about cyclical deps.
	#Class['httpd'] -> Class['koji::hub']

	package { 'koji-web': ensure => installed }

	file { '/etc/httpd/conf.d/kojiweb.conf':
		content => template('koji/web/kojiweb.conf.erb'),
		notify => Service['httpd'],
		require => Package['koji-web'],
	}
	file { '/etc/kojiweb/kojihubca.crt':
		ensure => link,
		target => '/etc/pki/tls/certs/cacert-class3.crt',
		require => Package['koji-web'],
	}

	case $auth {
		kerberos: {
			if( $realm == 'NONE' ) {
				fail('If you use Kerberos authentication, you must specify a $realm.')
			}
			class {'koji::web::kerberos': }
		}
		ssl: { fail('SSL auth not yet implemented.') }
		default: { fail('Unrecognized auth type for DB.') }
	}
}

class koji::web::kerberos {
	# Koji-web's keytab.
	file { '/etc/kojiweb/web.keytab':
		ensure => present,
		owner => 'root', group => 'apache',
		mode => '640',
		notify => Service['httpd'],
		require => Package['koji-web'],
	}
	# mod_auth_kerb's keytab.
	file { '/etc/httpd/http.keytab':
		ensure => present,
		owner => 'root', group => 'apache',
		mode => '640',
		notify => Service['httpd'],
	}
}
