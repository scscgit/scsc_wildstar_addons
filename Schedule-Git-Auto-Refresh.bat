@SET cur=%cd%
@SET vbs=..\pull_addons_from_git.vbs

@echo Creating a file in the directory above the current one, that will be periodically run: %vbs%

>"%vbs%" (
echo Dim s
echo Set s = CreateObject("WScript.Shell"^)

echo s.CurrentDirectory = "%cur%\..\"
echo s.Run "cmd.exe /c git -C Addons fetch origin master & cmd.exe /c git -C Addons checkout master & cmd.exe /c git -C Addons reset origin/master", 0
)

@echo.
@echo Creating the scheduled task

SchTasks /Create /SC HOURLY /TN "Git Pull WildStar Addons" /TR "%cur%\%vbs%"

@echo.
@echo All done.
@pause
