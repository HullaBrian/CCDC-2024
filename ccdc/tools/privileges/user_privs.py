# Get a list of all users on the system that have a shell.
def getUsers():

	passwds = open("/etc/passwd", "r")
	pass_entries = passwds.readlines()
	passwds.close()
	users = []
	shells = ["sh", "bash", "zsh", "csh"]
	for entry in pass_entries:
		if any("/bin/"+shell in entry for shell in shells):
			users.append(entry.split(":")[0])

	return(users)

# Make a dictionary of {user: [groups they're in]} for users with shells
def getUserGroups():

	groups = open("/etc/group", "r")
	group_entries = groups.readlines()
	groups.close()

	users = getUsers()

	user_groups = {user: [] for user in users}

	for user in users:
		for entry in group_entries:
			if user in entry:
				user_groups[user].append(entry.split(":")[0])

	return(user_groups)

# Get a list of all users with administrative privileges.
def getRootUsers():

	admins = []

	user_groups = getUserGroups()

	admin_groups = ["root", "wheel", "admin"]

	for user in user_groups:
		if any(grp in user_groups[user] for grp in admin_groups):
			admins.append(user)

	return(admins)


print "\n".join(getUsers())
print "\n".join(getRootUsers())