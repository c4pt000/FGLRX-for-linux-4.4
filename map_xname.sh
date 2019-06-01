#!/bin/sh
#
# Copyright (c) 2008-2009, 2010, 2011 Advanced Micro Devices, Inc.
#
# Purpose: 
#   Maps internal xDDD names to well known names for X Window versions
# Input :  
#   $1 - X version in the x???_[64a] format
# Return: 
#   Well known X name

case $1 in
    xpic | x690 | x7??)       echo "X.Org 6.9 or later";;
    xpic_64a | x690_64a | x7??_64a)   echo "X.Org 6.9 or later 64-bit";;
    *)          echo "Unknown X Window";;
esac
