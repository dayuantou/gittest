#!/bin/bash
#author by :Sundy.wang
#describe:A key produting version.

export PATH=.:$PATH
export OUT_HOST_ROOT=.
#date=$(date +%t)
#echo "=====Build time:"$(date)"===="
start='date'
echo "argume:$@"
echo "scname:$0"
ap_pwd=$(pwd)
echo "=====111111path<"$(pwd)">==="${HOME}"==="
my_code_path=${HOME}"/SEND_VERSION"
cd $my_code_path
cd ..
my_path=$(pwd)
echo "=====222path<"$(pwd)">========"
cd $ap_pwd
echo $my_code_path
echo $my_path
echo $ap_pwd
echo "=============>>PATH<<"$(pwd)">>========"

if [ "$3" = "" ]
	then
    echo -e "\033[31;1m Please Enter 3 parameter !!.\033[0m"
    exit
fi

echo "======check tool support======"
tool_table=(tree md5sum dos2unix unix2dos)
for i in "${!tool_table[@]}"
do
    which ${tool_table[$i]}
    if [ "$?" != "0" ]
    then
        sudo apt-get install -y ${tool_table[$i]}
        if [ "$?" != "0" ]
        then
            echo "Error: no such [ ${tool_table[$i]} ] tool"
            exit -1
        else
            echo "Install [ ${tool_table[$i]} ] sucess"
        fi
    fi
done

cp -r $my_code_path/$1/qdsp6m.qdb $(pwd)/quectel_build/packaged_file/modem/.
if [[ $? -eq 0 ]];
then 
    echo "copy scuessful"
else
    echo "copy fail"
    exit -1;
fi

cp -r $my_code_path/$1/qdsp6sw.mbn $(pwd)/quectel_build/packaged_file/modem/.
if [[ $? -eq 0 ]];
then 
    echo "copy scuessful"
else
    echo "copy fail"
    exit -1;
fi

cp -r $my_code_path/$1/orig_MODEM_PROC_IMG_sdx55.genauto.prodQ.elf  $(pwd)/quectel_build/packaged_file/modem/.
if [[ $? -eq 0 ]];
then 
    echo "copy scuessful"
else
    echo "copy fail"
    exit -1;
fi

rm -fr $(pwd)/SA515M_modem/modem_proc/build/ms/bin/sdx55.genauto.prod/configs
rm -fr $(pwd)/SA515M_modem/modem_proc/build/ms/bin/sdx55.genauto.prod/so   #lucky.meng 2019.08.13 rm -rf old so files
rm -fr $(pwd)/SA515M_modem/modem_proc/mcfg/configs/mcfg_sw/LE
rm -fr $(pwd)/SA515M_modem/modem_proc/mcfg/configs/mcfg_hw/LE
mcfg_mbn_path=$(pwd)"/SA515M_modem/modem_proc/build/ms/bin/sdx55.genauto.prod/configs"
mcfg_mbn_so_path=$(pwd)"/SA515M_modem/modem_proc/build/ms/bin/sdx55.genauto.prod/so"  #lucky.meng 2019.08.13 add so path
oem_sw_path=$(pwd)"/SA515M_modem/modem_proc/mcfg/configs/mcfg_sw/LE"
oem_hw_path=$(pwd)"/SA515M_modem/modem_proc/mcfg/configs/mcfg_hw/LE"
if [ ! -d "$mcfg_mbn_path" ]
then
    mkdir -p ${mcfg_mbn_path}
fi

if [ ! -d "$mcfg_mbn_so_path" ]
then
    mkdir -p ${mcfg_mbn_so_path}
fi

if [ ! -d "$oem_sw_path" ]
then
    mkdir -p ${oem_sw_path}
fi
if [ ! -d "$oem_hw_path" ]
then
    mkdir -p ${oem_hw_path}
fi
cp -fr $my_code_path/$1/mcfg/configs/* ${mcfg_mbn_path}
cp -fr $my_code_path/$1/mcfg/so/* ${mcfg_mbn_so_path}  #lucky.meng 2019.08.13 copy so files to linux 
cp -fr $my_code_path/$1/mcfg/configs/oem_sw.txt ${oem_sw_path}
touch  $oem_hw_path/oem_hw.txt

if [[ $? -eq 0 ]];
then 
    echo "copy scuessful"
else
    echo "copy fail"
    exit -1;
fi

#要先将编译出来的modem的bin文件 mba.mbn ，qdsp6sw.mbn copy到 quectel_build/packaged_file/modem/再去执行下面的脚本
cd  $ap_pwd/quectel_build

./quectel_do.sh do $1
if [ $? -ne 0 ]; then
	echo "quectel_do.sh run failed, Please check !!!!!!!!!!!!!"
	exit 1
fi

cd  $ap_pwd/common/build
echo "============="$(pwd)"============"
rm -rf ./NON-HLOS.ubi
./ModemUBI\&\&Updatafiles_gen.sh
chmod -R 777 ../../SA515M_apps/apps_proc/poky/build/tmp-glibc/deploy/images/sa515m/*

echo "=========pwd:"$(pwd)
if [ -d $my_path/$2 ]; 
then
    echo "$2 exit!"
else
    echo "=========The folder no exit!======="
    mkdir -p $my_path/$2
    mkdir -p $my_path/$2/upgrade
    mkdir -p $my_path/$2/dbg
    mkdir -p $my_path/$2/update
    mkdir -p $my_path/$2/update/firehose
if [ "$4" != "" ];then
    mkdir -p $my_path/$2/singlepacket
fi
fi

echo "========= copy update begin============="
cp ./nand/NON-HLOS.ubi   $my_path/$2/update/.

cd  $ap_pwd/quectel_build
#copy sbl, aop, tz ,uefi
cp ./packaged_file/quecrw/quecrw.ubi ./packaged_file/sbl/xbl_cfg.elf ./packaged_file/sbl/sbl1.mbn ./packaged_file/aop/aop.mbn ./packaged_file/tz/tz.mbn ./packaged_file/tz/hyp.mbn ./packaged_file/tz/devcfg.mbn ./packaged_file/tz/devcfg_auto.mbn ./packaged_file/tz/cmnlib.mbn ./packaged_file/tz/km4.mbn ./packaged_file/tz/haventkn.mbn  ./packaged_file/uefi/uefi.elf ./packaged_file/uefi/tools.fv  $my_path/$2/update/.
cp ./packaged_file/contents.xml $my_path/$2/.

#copy the firehose relate
rm -rf $my_path/$2/update/firehose/*
cp -rf ./packaged_file/firehose/*  $my_path/$2/update/firehose
rm -rf $my_path/$2/update/firehose/*_factory.xml
#去掉firehose 配置脚本里，擦除，烧录 cefs.mbn 这两行，因这是升级版本
#sed -i '/erase/{$!N;/cefs\.mbn/{d}}'  $my_path/$2/update/firehose/rawprogram_nand_*
#cd $my_path/$2/update/firehose/
#filename=rawprogram_nand_*
#mv $(basename $filename) $(basename $filename .xml)_update.xml

# copy partition files form apps_proc, the partition different for different project
cd  $ap_pwd
echo "=== 1  copy partition files form apps_proc==="
cp ./common/build/nand/partition.mbn  $my_path/$2/update/.
cp ./common/config/nand/partition_nand.xml  $my_path/$2/update/.
cp ./common/build/nand/multi_image.mbn  $my_path/$2/update/.
cp ./common/sectools/resources/build/fileversion2/sec.dat $my_path/$2/update/.
# 去掉 partition_nand.xml 里下载cefs.mbn 那行，因为这是update版本
sed -i '/cefs\.mbn/{d}' $my_path/$2/update/partition_nand.xml

# copy linux bin
echo “======copy  linux bin to update firmware package  begin======”
cd $ap_pwd/SA515M_apps/apps_proc/poky/build/tmp-glibc/deploy/images/sa515m
cp abl.elf $my_path/$2/update/.
cd $ap_pwd/SA515M_apps/apps_proc/poky/build/tmp-glibc/deploy/images/sa515m
cp sa515m-sysfs.ubi sa515m-boot.img ipa-fws/ipa_fws.elf oemapp.ubi usrdata.ubi $my_path/$2/update/.

cd $ap_pwd/common/build/nand/apdp
cp apdp.mbn $my_path/$2/update/.

rm -rf rootfs
mkdir rootfs
fakeroot tar xf system-rootfs.tar.gz -C rootfs/
cd rootfs/.
tree -i -f -p -s > ../file-in-system-image.txt
cp -rf ../file-in-system-image.txt  $my_path/$2/dbg/.
rm -rf rootfs

echo "========= copy dbg begin============="
cd  $ap_pwd
cp -rf ./quectel_build/packaged_file/modem/*.elf  $my_path/$2/dbg/.
cp -rf ./quectel_build/packaged_file/sbl/*.elf  $my_path/$2/dbg/.
cp -rf ./quectel_build/packaged_file/aop/*.elf  $my_path/$2/dbg/.
cp -rf ./quectel_build/packaged_file/tz/cmnlib.mbn $my_path/$2/dbg/.
cp -rf ./quectel_build/packaged_file/tz/cmnlib64.mbn $my_path/$2/dbg/.
cp -rf ./quectel_build/packaged_file/tz/*.elf  $my_path/$2/dbg/.
#cp $ap_pwd/SA515M_apps/apps_proc/poky/build/tmp-glibc/deploy/images/sa515m-perf/vmlinux $my_path/$2/dbg/.
cp $ap_pwd/SA515M_apps/apps_proc/poky/build/tmp-glibc/deploy/images/sa515m/vmlinux $my_path/$2/dbg/.
cp -rf $my_code_path/$1/msg_hash* $my_path/$2/dbg/.

echo "=========zip begin============="
cd $my_path/$2

echo "==========<FACTORY_VER>==================="
cd $ap_pwd/common/build

echo "===========[factory]path"$(pwd)"==========="
if [ -d $my_path/$3 ];
then 
    echo "$3 exit!"
else
    echo "=======The folder no exit!====="
    mkdir -p $my_path/$3
    mkdir -p $my_path/$3/update
    mkdir -p $my_path/$3/update/firehose
fi

echo ""
echo ""
echo "======= copy factory update begin====="
cp ./nand/NON-HLOS.ubi   $my_path/$3/update/.


cd  $ap_pwd/quectel_build
#copy sbl, aop, tz ,uefi
cp ./packaged_file/quecrw/quecrw.ubi ./packaged_file/sbl/xbl_cfg.elf ./packaged_file/sbl/sbl1.mbn ./packaged_file/aop/aop.mbn ./packaged_file/tz/tz.mbn ./packaged_file/tz/hyp.mbn ./packaged_file/tz/devcfg.mbn  ./packaged_file/tz/devcfg_auto.mbn ./packaged_file/tz/cmnlib.mbn ./packaged_file/tz/km4.mbn ./packaged_file/tz/haventkn.mbn ./packaged_file/uefi/uefi.elf ./packaged_file/uefi/tools.fv  $my_path/$3/update/.
cp ./packaged_file/contents.xml $my_path/$3/.

#copy the firehose relate
rm -rf $my_path/$3/update/firehose/*
cp -rf ./packaged_file/firehose/*  $my_path/$3/update/firehose
rm -rf $my_path/$3/update/firehose/*_update.xml

#cd $my_path/$3/update/firehose/
#filename=rawprogram_nand_*
#mv $(basename $filename) $(basename $filename .xml)_factory.xml

# copy partition files form apps_proc, the partition different for different project
cd  $ap_pwd
echo "=== 1  copy partition files form apps_proc==="
cp ./common/build/nand/partition.mbn  $my_path/$3/update/.
cp ./common/config/nand/partition_nand.xml  $my_path/$3/update/.
cp ./common/build/nand/multi_image.mbn  $my_path/$3/update/.
cp ./common/sectools/resources/build/fileversion2/sec.dat $my_path/$3/update/.
#copy cefs.mbn, factory.xqcn
cp ./QCN/$1/cefs.mbn  $my_path/$3/update/.
cp ./QCN/$1/factory.xqcn  $my_path/$3/update/.

# copy linux bin
echo “======copy  linux bin to update firmware package  begin======”
cd $ap_pwd/SA515M_apps/apps_proc/poky/build/tmp-glibc/deploy/images/sa515m
cp abl.elf $my_path/$3/update/.

cd $ap_pwd/common/build/nand/apdp
cp apdp.mbn $my_path/$3/update/.
cd $ap_pwd/SA515M_apps/apps_proc/poky/build/tmp-glibc/deploy/images/sa515m
cp sa515m-boot.img ipa-fws/ipa_fws.elf oemapp.ubi usrdata.ubi $my_path/$3/update/.

if [ -f sa515m-factory-sysfs.ubi ];
then
    cp sa515m-factory-sysfs.ubi $my_path/$3/update/sa515m-sysfs.ubi
else
    cp sa515m-sysfs.ubi $my_path/$3/update/.
fi


if [ "$4" != "" ];then
    cd  $ap_pwd/quectel_build
    echo "========= To generate single package  start ============="
    cp ./qfwflash $my_path/$2/singlepacket/
    ./quec_fh $my_path/$2 $my_path/$2/singlepacket/$1.img
    #./quec_fh $my_path/$2 $my_path/$2/singlepacket/$1.img >/dev/null 2>&1
    ./quec_fh $my_path/$2 $my_path/$2/singlepacket/$1.img 
    echo "========= To generate single package end ============="
fi

echo "======zip begin======"
cd $my_path/$3

echo "=====Del tmp folder ($1)and($2)======"
cd $my_path

MD5_path1=$my_path/$2/
MD5_path2=$my_path/$3/

echo "$MD5_path1, $MD5_path2"
typeset -u TO_UPPER
if [ -d "$MD5_path1" ] && [ -d "$MD5_path2" ]
then
	for (( m=1; $m<=2; m++ ))
	do
		md5_path=`eval echo '$MD5_path'"$m"`
		cd $md5_path
        chmod +444 -R ./
		echo "PATH: $md5_path"
    	echo -e "\033[32m\tmd5 path:\033[0m\n\t[ $(pwd) ]"
		rm md5.txt
		echo -e "VERSION:1.0\nFILE:START" > md5.txt
    	n=`tree -if --noreport | sed '/\.\/dbg/d' | wc -l`
    	for (( i=1; $i<=$n;i++ ))
    	do
    	    md5_file=`tree -if --noreport | sed '/\.\/dbg/d' |sed -n "$i""p"`
    	    if [ -d "$md5_file" ] || [ "$md5_file" = "./md5.txt" ]
    	    then
    	        continue
    	    fi
			echo "md5 file [ $md5_file ]"
    	    md5_info=`md5sum $md5_file`
            if [[ $? -eq 1 ]]
            then
                echo -e "\033[31mError:\033[0m file [ $md5_file ]"
                exit 1
            fi
    	    TO_UPPER=`echo $md5_info | awk '{printf $1}'`
    	    file_md5=`echo $md5_info | awk '{printf $2}' | sed 's/\//\\\\/g'`
    	    echo "FILE:${file_md5:1}:$TO_UPPER" >> md5.txt
    	done
    	echo "FILE:END" >> md5.txt
		unix2dos md5.txt
    	cd - > /dev/null
	done
else
	echo "No such path $1 or $2"
	exit 1
fi



#echo "=====Build time:"$(date)"===="
minu_time=$(($SECONDS/60))
sec_time=$(($SECONDS%60))

echo "===============Build_time:"$minu_time"m"$sec_time"s==============="
echo "==========================================-"
echo "===============Build version==============="
#cat $ap_pwd/SDX55_apps/apps_proc/poky/build/tmp-glibc/work/sdxprairie-oe-linux-gnueabi/machine-image/1.0-r0/rootfs/etc/quectel-project-version

77777777777777777777
555555555555555
99999999999999
1010101010101

