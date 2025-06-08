#!/bin/bash

echo "🚫 Deteniendo servicio de PostgreSQL..."
systemctl stop postgresql

echo "🧹 Eliminando paquetes de PostgreSQL..."
apt purge -y postgresql* postgresql-client* postgresql-contrib* libpq-dev

echo "🗑️ Eliminando archivos de configuración y datos..."
rm -rf /etc/postgresql/
rm -rf /etc/postgresql-common/
rm -rf /var/lib/postgresql/
rm -rf /var/log/postgresql/

echo "👤 Eliminando usuario y grupo postgres si existen..."
if id "postgres" &>/dev/null; then
    deluser --remove-home postgres
    delgroup postgres
fi

echo "🧼 Eliminando dependencias no usadas..."
apt autoremove -y
apt autoclean

echo "✅ PostgreSQL ha sido completamente eliminado."
