#!/bin/bash

choice=$(printf "󰓅 Performance\n󰾅 Balanced\n󰌪 Power Saver" | rofi -dmenu -p "Power Mode")

case "$choice" in
  *Performance) powerprofilesctl set performance ;;
  *Balanced) powerprofilesctl set balanced ;;
  *Saver) powerprofilesctl set power-saver ;;
esac
