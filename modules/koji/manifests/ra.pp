
class koji::ra($auth, $hub, $realm = 'NONE') {
	package { 'koji-utils': ensure => installed }

	service { 'kojira':
		ensure => running,
		enable => true,
		hasstatus => true,
		hasrestart => true,
		require => Package['koji-utils'],
	}
	file { '/etc/kojira/kojira.conf':
		ensure => present,
		content => template('koji/ra/kojira.conf.erb'),
		notify => Service['kojira'],
		require => Package['koji-utils'],
	}
	# Link to Koji-hub's CA, so kojira can properly verify it.
	file { '/etc/kojira/kojihubca.crt':
		ensure => link,
		target => '/etc/pki/tls/certs/cacert-class3.crt',
		require => Package['koji-builder'],
	}
	case $auth {
		kerberos: {
			if( $realm == 'NONE' ) {
				fail('If you use Kerberos authentication, you must specify a $realm.')
			}
			class {'koji::ra::kerberos': }
		}
		ssl: { fail('SSL auth not yet implemented.') }
		default: { fail('Unrecognized auth type for DB.') }
	}
}

class koji::ra::kerberos {
	# Kojira's keytab.
	file { '/etc/kojira/kojira.keytab':
		ensure => present,
		owner => 'root', group => 'root',
		mode => '640',
		notify => Service['kojira'],
		require => Package['koji-utils'],
	}
}
