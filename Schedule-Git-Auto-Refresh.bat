@SET cur=%cd%
@SET vbs=..\pull_addons_from_git.vbs

@echo Creating a file in the directory above current one: %vbs% that will be periodically run

>"%vbs%" (
echo Dim s
echo Set s = CreateObject("WScript.Shell"^)

echo s.CurrentDirectory = "%cur%\..\"
echo s.Run "cmd.exe /c git -C Addons fetch origin master", 0
echo s.Run "cmd.exe /c git -C Addons reset origin/master", 0
)

@echo.
@echo Creating a scheduled task

SchTasks /Create /SC HOURLY /TN "Git Pull WildStar Addons" /TR "%cur%\%vbs%"

@echo.
@echo All done.
@pause
