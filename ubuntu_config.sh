# Bash script
# This script prepares CHIA Plotter system
# Version 1.6 - Teo's Setup - now script is interactial
# 13 September 2021
# by Svetoslav Tolev

# ########### 

read -p "Welcome to Chia Plotter and Harvester system configurator. Press ENTER to continue."
read -p "Starting configuration. Each and evey command now requests pressing ENTER to continue"

# Next few lines upgrade systm to latest level

read -p "Starting system updateAre you sure? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    apt update
    apt upgrade -y
fi

######## Next few lines will upgrade the kernel to solve the issue with LAN Adapter
read -p "Now we will upgrade the kernel to fix the isssues with Intel LAN adapter. Are you sure?" -n 1 -r

# Download kernel files
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Downloading correct kernel level"
    wget https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.12.19/amd64/linux-headers-5.12.19-051219-generic_5.12.19-051219.202107201136_amd64.deb
    wget https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.12.19/amd64/linux-headers-5.12.19-051219_5.12.19-051219.202107201136_all.deb
    wget https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.12.19/amd64/linux-image-unsigned-5.12.19-051219-generic_5.12.19-051219.202107201136_amd64.deb
    wget  https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.12.19/amd64/linux-modules-5.12.19-051219-generic_5.12.19-051219.202107201136_amd64.deb
    # Start install
    read -p  "Install new kernel. At the end will ask for approval to restart services. Please confirm selected."
    sudo dpkg -i *.deb
    # Remove kernel files
    echo "Removing downloaded kernal as it's already installed"
    rm linux-headers-5.12.19-051219-generic_5.12.19-051219.202107201136_amd64.deb
    rm linux-headers-5.12.19-051219_5.12.19-051219.202107201136_all.deb
    rm linux-image-unsigned-5.12.19-051219-generic_5.12.19-051219.202107201136_amd64.deb
    rm linux-modules-5.12.19-051219-generic_5.12.19-051219.202107201136_amd64.deb
fi 

#  Change host name

read -p "Do you want to change hostname?" -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
    #Assign existing hostname to $hostn
    hostn=$(cat /etc/hostname)

    #Display existing hostname
    echo "Existing hostname is $hostn"

    #Ask for new hostname $newhost
    echo "Enter new hostname: "
    read newhost
    read -p "Hostname will be changed to $newhost. Please confirm [YN]"
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        sudo sed -i "s/$hostn/$newhost/g" /etc/hosts
        sudo sed -i "s/$hostn/$newhost/g" /etc/hostname

        #display new hostname
        echo "Your new hostname is $newhost"
    fi 

fi

# ask for password change

read -p "Do you want to chnge user chpt password?" -n 1 -ram
if [[ $REPLY =~ ^[Yy]$ ]]
then
    passwd chpt
fi





# Disable sleep
read -p "Disable sleep mode"
systemctl mask sleep.target suspend.target hybrid-sleep.target hibernate.target




# Create a new partition for CHIA Temp

read -p "Create a new partition"
# echo "/dev/nvme0n1p5 : start=    88057856, size=   912157327, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4" > sudo sfdisk /dev/nvme0
# sfdisk /dev/nvme0n1

(
echo n # Add a new partition
echo 5 # Partition number
echo   # First sector (Accept default: 1)
echo   # Last sector (Accept default: varies)
echo w # Write changes
) | sudo fdisk /dev/nvme0n1



read -p "Create Logical volume"


sudo vgcreate plotvg /dev/nvme0n1p5
sudo lvcreate -n tmpdir -l 100%FREE plotvg
sudo mkfs.xfs /dev/plotvg/tmpdir
sudo mkdir -p /chia/tmpdir
sudo mkdir /chia/dest
# sudo mount //dev/plotvg/tmpdir /chia/tmpdir
echo "/dev/plotvg/tmpdir    /chia/tmpdir   xfs" >> /etc/fstab

#sudo mount -t tmpfs -o size=110G tmpfs /mnt/ram/
# tmpfs       /mnt/ramdisk tmpfs   nodev,nosuid,noexec,nodiratime,size=1024M   0 0
echo "tmpfs       /chia/tmpdir2 tmpfs   size=110G" >> /etc/fstab

mount -a




### Install MadMax Plotter

mkdir chia-plotter
apt install -y libsodium-dev cmake g++ git build-essential
# Checkout the source and install
git clone https://github.com/madMAx43v3r/chia-plotter.git 
cd chia-plotter

git submodule update --init
./make_devel.sh
./build/chia_plot --help




### TODO - check how to execute commnds as it's into the harvester service

# git clone https://github.com/Chia-Network/chia-blockchain.git -b latest --recurse-submodules
# cd chia-blockchain
# sh install.sh
# . ./activate




###

read "Please enter IP address of the full node?"

scp chiaplot@$REPLY:.chia/mainnet/config/ssl/ca/* .

chia init -c .


### TODO - Edit confg.yaml - to add full node




#### Add harverster service

read -p "Adding CHIA Harvester service"

wget https://raw.githubusercontent.com/100lv/teddyinstall/main/chiaharvester.service
mv chiaharvester.service /etc/systemd/system
sudo systemctl enable chiaharvester.service
sudo systemctl start chiaharvester.service



### Add CRON for chia plot for Mad Max Plotter

wget https://github.com/100lv/ubuntuinstall/raw/main/chia_madmax_start.sh
chmod +x chia_madmax_start.sh
{  crontab -l; echo "@reboot /home/chpt/chia_madmax_start.sh";  | crontab - }


# wget https://github.com/100lv/ubuntuinstall/raw/main/madmax.service
# mv madmax.service /etc/systemd/system
# sudo systemctl enable madmax.service







###############################
# Some fine tunning
###############################



##### Remove snap
# First snaps

read -p "Remo snaps services - you don't need them"

 snap remove --purge lxd
 snap remove --purge core18
 snap remove --purge core20
 snap remove --purge snapd

# Clear snap Cache

 rm -rf /var/cache/snapd/
 apt autoremove --purge snapd gnome-software-plugin-snap -y
 rm -fr ~/snap


# Stop snap service

apt-mark hold snapd




#################### Add disk subsystem

# Configure iSCSI - TODO
sudo apt install open-iscsi

### Change initiator to hostname
$changeh='ubuntu/'$(hostname)
sudo sed -i 's/'$changeh'/g'  /etc/iscsi/initiatorname.iscsi





# Add LUN - TODO

# List all devices - TODO
# Ask to choose - TODO
# Check if it's empty - TODO
# Add FS and mountpoint - TODO


# Check FS - TODO


# Add FS to Chia harvester


# Finish

read -p "System should be rebooted
reboot