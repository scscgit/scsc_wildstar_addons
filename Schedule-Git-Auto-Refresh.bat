echo git -C Addons pull origin master > ../pull_addons_from_git.bat
SchTasks /Create /SC HOURLY /TN "Git Pull WildStar Addons" /TR "%cd%\..\pull_addons_from_git.bat"