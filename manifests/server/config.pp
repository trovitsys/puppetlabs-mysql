# See README.me for options.
class mysql::server::config {

  $options = $mysql::server::options
  $includedir = $mysql::server::includedir

  File {
    owner  => 'root',
    group  => $mysql::server::root_group,
    mode   => '0400',
  }

  if $includedir and $includedir != '' {
    file { $includedir:
      ensure  => directory,
      mode    => '0755',
      recurse => $mysql::server::purge_conf_dir,
      purge   => $mysql::server::purge_conf_dir,
    }
  }

  $logbin = pick($options['mysqld']['log-bin'], $options['mysqld']['log_bin'], false)

  if $logbin {
    $logbindir = mysql_dirname($logbin)
    $logbindir_attr = {
      ensure => directory,
      mode   => '0755',
      owner  => $options['mysqld']['user'],
      group  => $options['mysqld']['user'],
    }
    ensure_resource('file', $logbindir, $logbindir_attr)
    }
  }

  $relaylog = pick($options['mysqld']['relay-log'], $options['mysqld']['relay_log'], false)

  if $relaylog {
    $relaylogdir = mysql_dirname($relaylog)
    $relaylogdir_attr = {
      ensure => directory,
      mode   => '0755',
      owner  => $options['mysqld']['user'],
      group  => $options['mysqld']['user'],
    }
    ensure_resource('file', $relaylogdir, $relaylogdir_attr)
  }

  if $mysql::server::manage_config_file  {
    file { 'mysql-config-file':
      path    => $mysql::server::config_file,
      content => template('mysql/my.cnf.erb'),
      mode    => '0644',
    }
  }

  if $options['mysqld']['ssl-disable'] {
    notify {'ssl-disable':
      message =>'Disabling SSL is evil! You should never ever do this except if you are forced to use a mysql version compiled without SSL support'
    }
  }
}
