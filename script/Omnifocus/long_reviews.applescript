property output: {}
tell application "OmniFocus"
	tell default document
		repeat with aProject in every flattened project
            log("" & next review date of aProject)
			if ((next review date of aProject - (current date)) > 14 * days) then set end of my output to {name of aProject & " - " & next review date of aProject & "\n"}
		end
		return output
	end tell
end tell

