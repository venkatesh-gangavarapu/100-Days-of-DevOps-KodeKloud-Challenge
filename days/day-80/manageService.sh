# Job 2: manage-services (Freestyle)
# Type: Freestyle project
# Agent: stapp01
#
# Build Triggers:
# → Build after other projects are built
# → Projects to watch: nautilus-app-deployment
# → Trigger only if build is stable
#
# Build Steps → Execute shell:

sudo systemctl restart httpd
echo "httpd restarted successfully"
sudo systemctl status httpd | grep Active
