Config = {}

-- ✅ Update Checker
Config.CheckForUpdates = true
Config.RepoUrl = "https://github.com/sstumpss/ag_hostilecooldown"
-- Enable debug logging for the update checker (prints extra info to server console)
Config.Debug = true

-- ⚙️ Hostile Cooldown Settings
-- NOTE: This value is now in minutes. The server will convert to seconds when sending to clients.
Config.CooldownTime = 10 -- minutes (default: 10 minutes)
Config.ExcludedJobs = { 'police', 'ambulance' }
Config.AdminPermission = 'group.god'

-- 🎨 Paintball Integration
Config.PaintballResources = {
    'pug-paintball',
    'nass_paintball'
}

-- 🏥 Integration
Config.UseWasabiAmbulance = true -- set to false if not using wasabi_ambulance


-- 🧩 UI
Config.UseTopBanner = true -- enables ox_lib progress-style banner