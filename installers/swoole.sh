#!/usr/bin/env bash

/usr/bin/pecl install swoole-1.9.1

echo 'extension=swoole.so' | tee /etc/php/7.0/mods-available/swoole.ini
phpenmod swoole
