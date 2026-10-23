use scripting additions

-- Skim's built-in tab shortcut uses Option-Command plus a number.
try
	tell application "System Events"
		if frontmost of application process "Skim" then
			key code 19 using {option down, command down}
		end if
	end tell
on error errorText number errorNumber
	display alert "Skim のタブ切替を実行できません" message (errorText & return & return & "システム設定 → プライバシーとセキュリティで、Skim のアクセシビリティと System Events の操作を許可してください。") as warning
end try
