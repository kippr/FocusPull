#!env osascript
set dateString to "" & (day of (current date)) & "-" & month of (current date) & "-" & year of (current date)
tell application "OmniFocus"
	tell default document
		set lstActiveTasks to every flattened task whose completed is false and blocked is false and status of containing project is active and parent task is not missing value
		set lstAllProjects to every flattened project
		set lstActiveProjects to every flattened project whose status is active and singleton action holder is false
		repeat with focusProject in lstActiveProjects
			log ("Project: " & name of focusProject)
		end repeat
		set lstRemainingTasks to every flattened task whose completed is false and (status of containing project is on hold or status of containing project is active) and parent task is not missing value
		set lstRemainingProjects to every flattened project whose status is active or status is on hold
		set lstAllTasks to every flattened task whose parent task is not missing value
		set headers to "date, active tasks, active projects, remaining tasks, remaining projects, all tasks, all projects, guide"
		set output to dateString & ", " & (count of lstActiveTasks) & ", " & (count of lstActiveProjects) & ", " & (count of lstRemainingTasks) & ", " & (count of lstRemainingProjects) & ", " & (count of lstAllTasks) & ", " & (count of lstAllProjects) & ", 0"
		return headers & "
" & output
	end tell
end tell
