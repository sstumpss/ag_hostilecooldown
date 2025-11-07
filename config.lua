Config = {}

-- ✅ Update Checker
Config.CheckForUpdates = true
Config.RepoUrl = "https://github.com/sstumpss/ag_hostilecooldown"

-- ⚙️ Hostile Cooldown Settings
Config.CooldownTime = 600 -- seconds (10 minutes)
Config.ExcludedJobs = { 'police', 'ambulance' }
Config.AdminPermission = 'group.god'

-- 🏥 Integration
Config.UseWasabiAmbulance = true -- set to false if not using wasabi_ambulance

-- 🧩 UI
Config.UseTopBanner = true -- enables ox_lib progress-style banner
