#!/bin/bash

# ============================================================
# SKRIP INI DI-REMAKE OLEH ARRZ OFFICIAL (TELEGRAM: @arrzoffc)
# DILARANG UNTUK MEMPERJUALBELIKAN SKRIP INI, APALAGI MEMBAGIKANNYA SECARA GRATIS!
# GAK USAH NGEYEL! NGEYEL? MATI AJA LU, HIDUP LU GAK GUNA, KERJAANNYA CUMA MALING SC, JUAL/SHARE SC HASIL MALING
# ============================================================

echo "Masukkan nama location (contoh: SGP): "
read location_name
echo "Masukkan id location (contoh: 1): "
read locid
echo "Masukkan nama node (contoh: Nodes): "
read node_name
echo "Masukkan deskripsi (contoh: Panel by Arrz Official): "
read description
echo "Masukkan domain node (contoh: nodepanel.example.com): "
read domain
echo "Masukkan RAM (dalam MB): "
read ram
echo "Masukkan jumlah maksimum disk space (dalam MB): "
read disk_space

cd /var/www/pterodactyl || { echo "Direktori tidak ditemukan"; exit 1; }

echo "Membuat Location..."
php artisan p:location:make --short="$location_name" --long="$description"

echo "Membuat Node..."
php artisan p:node:make \
  --name="$node_name" \
  --description="$description" \
  --locationId="$locid" \
  --fqdn="$domain" \
  --public=1 \
  --scheme="https" \
  --proxy=0 \
  --maintenance=0 \
  --maxMemory="$ram" \
  --overallocateMemory=0 \
  --maxDisk="$disk_space" \
  --overallocateDisk=0 \
  --uploadSize=100 \
  --daemonListeningPort=8080 \
  --daemonSFTPPort=2022 \
  --daemonBase="/var/lib/pterodactyl/volumes"

echo " "
echo "Mengambil konfigurasi otomatis untuk Wings..."
NODE_ID=$(php artisan tinker --execute="echo optional(\Pterodactyl\Models\Node::latest()->first())->id;" | grep -E '^[0-9]+$' | tail -n 1)
if [ -z "$NODE_ID" ]; then
    echo "❌ Gagal mendapatkan Node ID dari database."
    echo "⚠️  Silakan konfigurasi Wings secara manual."
else
    echo "✅ Node ID terdeteksi: $NODE_ID"
    echo "Membuat file konfigurasi..."
    mkdir -p /etc/pterodactyl
    php artisan p:node:configuration "$NODE_ID" > /etc/pterodactyl/config.yml

    echo "Menyalakan Wings..."
    systemctl daemon-reload
    systemctl enable wings
    systemctl restart wings
    sleep 2
    if systemctl is-active --quiet wings; then
        echo " "
        echo -e "\e[1;32m[SUKSES] Wings berhasil dikonfigurasi dan AKTIF (Online)!\e[0m"
    else
        echo " "
        echo -e "\e[1;31m[WARNING] Wings gagal start otomatis. Cek 'systemctl status wings' untuk detail.\e[0m"
    fi
fi

echo " "
echo "Proses pembuatan location dan node telah selesai."
