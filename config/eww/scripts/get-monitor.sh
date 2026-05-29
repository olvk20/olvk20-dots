#!/usr/bin/env bash
hyprctl monitors -j | jq '[.[] | select(.focused==true)][0].id'
