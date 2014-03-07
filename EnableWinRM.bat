@echo off
winrm quickconfig -q
powershell Enable-PSRemoting -Force