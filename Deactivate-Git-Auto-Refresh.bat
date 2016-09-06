@SET cur=%cd%
@SET vbs=..\pull_addons_from_git.vbs

@echo Deleting a scheduled file in the directory above the current one: %vbs%
del "%vbs%"

@echo.
@echo Deactivating the scheduled task

SchTasks /Delete /TN "Git Pull WildStar Addons" /f

@echo.
@echo All done.
@pause
