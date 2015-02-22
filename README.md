# Pastr

Simple pastebin clone written with Perl/Mojolicious/MongoDB

## Dependencies

* Perl
* Mojolicious
* Mango module (Non-blocking MongoDB driver for Perl)
* MongoDB

## Installation

Simply clone or download the the repository, adjust the pastr.conf file and
execute either:

* morbo -f script/pastr (for development), or
* hypnotoad -f script/pastr (for production)

The app will then listen on either 127.0.0.1:3000 (development) or 0.0.0.0:8080
(production).

To access your app via a reverse proxy, create a minimal VHost like this:

    <VirtualHost *:80>
        ServerName pastr.markusko.ch
        ProxyPass / http://127.0.0.1:8080/
    </VirtualHost> 
