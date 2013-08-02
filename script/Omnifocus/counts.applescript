tell application "OmniFocus"
	tell default document
		tell (flattened tasks whose completed is false and blocked is false and status of containing project is active and parent task is not missing value)
			set {lstActiveTasks} to {name}
		end tell
		tell (flattened projects whose status is active)
			set {lstActiveProjects} to {name}
		end tell
		tell (flattened tasks whose completed is false and (status of containing project is on hold or status of containing project is active) and parent task is not missing value)
			set {lstRemainingTasks} to {name}
		end tell
		tell (flattened projects whose status is active or status is on hold)
			set {lstRemainingProjects} to {name}
		end tell
		tell (flattened tasks whose parent task is not missing value)
			set {lstAllTasks} to {name}
		end tell
		tell (flattened projects)
			set {lstAllProjects} to {name}
		end tell
		return {"active tasks", count of lstActiveTasks, "active projects", count of lstActiveProjects, "remaining tasks", count of lstRemainingTasks, "remaining projects", count of lstRemainingProjects, "all tasks", count of lstAllTasks, "all projects", count of lstAllProjects}
	end tell
end tell
