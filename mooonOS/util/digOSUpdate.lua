fs.delete("mooonOS/")
fs.delete("startup")
shell.run("wget", "https://raw.githubusercontent.com/ChefMooon/cc-scripts/refs/heads/mooonOS/mooonOS/digOS.lua startup")
os.reboot()