# Per user my.cnf configuration file
define mysql::client::my_cnf (
    $user,
    $host                  = 'localhost',
    $password               = '',
    $system_user            = 'root',
    $socket                 = '/var/lib/mysql/run/mysqld.sock',
    $mysql_client_socket    = true,
    $mysql_client_port      = false,
    $mysql_client_have_ssl  = false,
    $mysql_client_include   = true,
    $ssl_certs_path         = '',
    $ssl_ca_filename        = 'ca-cert.pem',
    $ssl_cert_filename      = 'client-cert.pem',
    $ssl_key_filename       = 'client-key.pem'
) {

    # define this here again cause we may invoke mysql::client
    # without having a server installed
    $config_path = $::operatingsystem ? {
        'CentOS'  => '/etc',
        default  => '/etc/mysql',
    }

    if ($mysql_client_have_ssl == true)
    {
        if ($ssl_certs_path == '') {
            if ($user == 'root') {
                $ssl_certs_real_path = "/${user}/certs"
            } else {
                $ssl_certs_real_path = "/home/${user}/certs"
            }
        } else {
            $ssl_certs_real_path = $ssl_certs_path
        }

        $mysql_client_ssl_ca    = "${ssl_certs_real_path}/${ssl_ca_filename}"
        $mysql_client_ssl_cert  = "${ssl_certs_real_path}/${ssl_cert_filename}"
        $mysql_client_ssl_key   = "${ssl_certs_real_path}/${ssl_key_filename}"

        $client_ssl_ca_priv_key    = extlookup('mysql_client_ssl_ca')
        $client_ssl_cert_priv_key  = extlookup('mysql_client_ssl_cert')
        $client_ssl_key_priv_key   = extlookup('mysql_client_ssl_key')

        file { $ssl_certs_real_path:
            ensure  => directory,
            owner   => $user,
            mode    => '0644',
            require => File[$title]
        }

        file { $mysql_client_ssl_ca:
            ensure  => present,
            content => "${client_ssl_ca_priv_key}\n",
            mode    => '0644',
            owner   => $user,
            group   => 'root',
            require => File[$ssl_certs_real_path]
        }

        file { $mysql_client_ssl_cert:
            ensure  => present,
            content => "${client_ssl_cert_priv_key}\n",
            mode    => '0644',
            owner   => $user,
            group   => 'root',
            require => File[$ssl_certs_real_path]
        }

        file { $mysql_client_ssl_key:
            ensure  => present,
            content => "${client_ssl_key_priv_key}\n",
            mode    => '0644',
            owner   => $user,
            group   => 'root',
            require => File[$ssl_certs_real_path]
        }

    }

    file { $title:
        owner   => $system_user,
        group   => 'root',
        mode    => '0600',
        content => template('mysql/client/my.cnf.erb'),
    }
}
