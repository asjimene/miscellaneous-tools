## PowerShell MSI ARP Cleanup

This tool is intended to identify and cleanup entries in the Windows Registry keys that contain Add/Remove Programs information. The script loops through the HKLM\SOFTWARE\[WOW6432Node]\Microsoft\Windows\CurrentVersion\Uninstall Registry keys, checks to see if there is a maching product code in HKEY_CLASSES-ROOT\Installers\Products. If a key does not exist in HKCR, the script can remediate by deleting the entry from ARP.

This script is still a work-in-progress, please test it exstensively before use!
I am not responsible for any damage caused by this tool!

Thanks to <https://adameyob.com/scripts/converting-guid-pid/> where I found an awesome function for converting the Product Code GUID to the format used in the registry!