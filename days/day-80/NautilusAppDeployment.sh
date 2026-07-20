# Job 1: nautilus-app-deployment (Freestyle)
# Type: Freestyle project
# Agent: stapp01
#
# Build Steps → Execute shell:

cd /var/www/html
sudo git fetch origin master
sudo git reset --hard origin/master
sudo chown -R sarah:sarah /var/www/html

# Post-build Actions:
# → Build other projects → manage-services
# → Trigger only if build is stable
