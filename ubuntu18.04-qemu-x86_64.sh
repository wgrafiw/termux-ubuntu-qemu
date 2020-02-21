#!/data/data/com.termux/files/usr/bin/bash
pkg up -y && pkg in wget proot qemu-user-x86_64 -y
folder=ubuntu-fs
if [ -d "$folder" ]; then
	first=1
	echo "skipping downloading"
fi
tarball="ubuntu.tar.gz"
if [ "$first" != 1 ];then
		wget "https://partner-images.canonical.com/core/bionic/current/ubuntu-bionic-core-cloudimg-amd64-root.tar.gz" -O $tarball
	cur=`pwd`
	mkdir -p "$folder"
	cd "$folder"
	echo "decompressing ubuntu image"
	proot --link2symlink tar -xf ${cur}/${tarball} --exclude='dev'||:
	echo "fixing nameserver, otherwise it can't connect to the internet"
	echo "nameserver 114.114.114.114" > ubuntu-fs/etc/resolv.conf
	cd "$cur"
fi
mkdir -p binds
bin=start-ubuntu.sh
echo "编写启动脚本"
cat > $bin <<- EOM
#!/bin/bash
cd \$(dirname \$0)
## unset LD_PRELOAD in case termux-exec is installed
unset LD_PRELOAD
command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r $folder -q qemu-x86_64"
if [ -n "\$(ls -A binds)" ]; then
    for f in binds/* ;do
      . \$f
    done
fi
command+=" -b /dev"
command+=" -b /proc"
## 取消注释以下行可以访问termux的主目录
#command+=" -b /data/data/com.termux/files/home:/root"
## 取消注释以下行以将/ sdcard直接安装到/
#command+=" -b /sdcard"
command+=" -w /root"
command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
command+=" TERM=\$TERM"
command+=" LANG=C.UTF-8"
command+=" /bin/bash --login"
com="\$@"
if [ -z "\$1" ];then
    exec \$command
else
    \$command -c "\$com"
fi
EOM

echo "修复shebang of $bin"
termux-fix-shebang $bin
echo "使$bin可执行"
chmod +x $bin
echo "你现在可以使用 ./${bin} 启动Ubuntu"
echo "如果遇到lib缺失请从/system/lib64找到对应lib复制到/data/data/com.termux/files/usr/lib"
echo "例如：cp /system/lib64/libm.so /data/data/com.termux/files/usr/lib"
