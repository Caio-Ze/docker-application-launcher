# Team Installation Guide

## 🏢 Docker Application Launcher - Team Deployment

This guide is for team leaders who want to deploy the Docker Application Launcher across their organization.

## 📋 Prerequisites for Team Members

Before installation, ensure each team member has:

- ✅ **macOS** (Intel or Apple Silicon)
- ✅ **Docker Desktop** installed and running
- ✅ **Terminal** access (basic knowledge helpful but not required)

## 🚀 One-Command Installation

Share this command with your team members:

```bash
curl -sSL https://raw.githubusercontent.com/Caio-Ze/docker-application-launcher/master/install.sh | bash
```

## 📱 What Each Team Member Gets

After installation, each team member will have:

### Terminal Access
- `dockerapps` - Main command
- `da` - Short alias
- `docker-app-launcher` - Full command

### Desktop Integration
- **"Docker Apps.command"** file on desktop
- Double-click to launch (perfect for non-technical users)

### Pre-configured Applications
- Dynamic Bounce Manager (example application)
- Template for adding more applications

## 🔧 Adding Team Applications

### Step 1: Create Application Configurations

Create JSON configuration files for your team's applications. Example:

```json
{
  "name": "Team Web App",
  "description": "Our main web application",
  "image": "your-company/web-app:latest",
  "ports": [
    {
      "host": "3000",
      "container": "3000",
      "description": "Web interface"
    }
  ],
  "volumes": [
    {
      "host": "$HOME/projects",
      "container": "/app/projects",
      "description": "Project files"
    }
  ],
  "environment": [
    {
      "name": "NODE_ENV",
      "value": "development",
      "description": "Environment mode"
    }
  ],
  "interactive": false,
  "remove_after_exit": true,
  "additional_flags": "--restart unless-stopped"
}
```

### Step 2: Distribute Configurations

Team members can add applications by:

1. **Creating files in**: `~/.docker-app-launcher/apps/`
2. **Using the template**: Copy from `~/.docker-app-launcher/apps/app-template.json`
3. **Team distribution**: Share JSON files via email, Slack, or version control

## 📊 Team Usage Scenarios

### For Developers
- Quick access to development environments
- Standardized Docker commands across team
- Easy switching between different project containers

### For Non-Technical Users
- Double-click desktop shortcut
- Simple menu interface
- No need to learn Docker commands

### For DevOps/Team Leads
- Centralized application management
- Consistent deployment across team
- Easy to add/remove applications

## 🎯 Best Practices for Teams

### 1. Standardize Application Names
Use consistent naming conventions:
- `company-web-app`
- `company-database`
- `company-api-server`

### 2. Include Helpful Descriptions
Make descriptions clear for all team members:
```json
{
  "name": "Customer Database",
  "description": "PostgreSQL database for customer management system"
}
```

### 3. Document Volume Mappings
Clearly explain what each volume does:
```json
{
  "volumes": [
    {
      "host": "$HOME/customer-data",
      "container": "/var/lib/postgresql/data",
      "description": "Customer database storage - DO NOT DELETE"
    }
  ]
}
```

### 4. Set Appropriate Defaults
- Use `"remove_after_exit": true` for development containers
- Use `"interactive": false` for background services
- Include restart policies for production-like containers

## 🔄 Updating Team Applications

### Method 1: Individual Updates
Team members can update their own configurations by editing files in `~/.docker-app-launcher/apps/`

### Method 2: Centralized Distribution
1. Maintain configurations in a shared repository
2. Team members can download updates:
   ```bash
   curl -O https://your-repo.com/configs/team-app.json
   mv team-app.json ~/.docker-app-launcher/apps/
   ```

### Method 3: Automated Updates
Create a script for team members:
```bash
#!/bin/bash
# update-team-apps.sh
cd ~/.docker-app-launcher/apps/
curl -O https://your-repo.com/configs/web-app.json
curl -O https://your-repo.com/configs/database.json
echo "✅ Team applications updated!"
```

## 🆘 Team Support

### Common Team Issues

1. **"I don't see the desktop shortcut"**
   - Check `~/Desktop/Docker Apps.command`
   - Re-run the installer if missing

2. **"The alias doesn't work"**
   - Restart terminal or run: `source ~/.zshrc`
   - Check if installation completed successfully

3. **"Docker image not found"**
   - Ensure team has access to your Docker registry
   - Check image names in configurations

4. **"Permission denied"**
   - Ensure Docker Desktop is running
   - Check user permissions for Docker

### Support Workflow

1. **First Level**: Check this documentation
2. **Second Level**: Verify Docker Desktop is running
3. **Third Level**: Re-run installation command
4. **Escalation**: Contact team lead or DevOps

## 📈 Scaling for Large Teams

### For 20+ Users
- Consider using a shared Docker registry
- Implement configuration management
- Create team-specific documentation
- Set up monitoring for Docker usage

### For Multiple Projects
- Use project-specific configuration directories
- Implement naming conventions
- Create project templates
- Document project-specific requirements

## 🔐 Security Considerations

### Volume Mappings
- Be careful with volume mappings to sensitive directories
- Use specific paths rather than mounting entire home directory
- Document what data is accessible to containers

### Network Access
- Consider which ports are exposed
- Document network requirements
- Use appropriate security groups if applicable

### Image Sources
- Use trusted Docker registries
- Implement image scanning if required
- Keep base images updated

## 📞 Getting Team Help

- **Documentation**: This guide and main README
- **Issues**: https://github.com/Caio-Ze/docker-application-launcher/issues
- **Team Lead**: Contact your team lead for organization-specific help
- **Configuration**: Check `~/.docker-app-launcher/apps/app-template.json` for examples

---

**Perfect for teams of any size - from 5 to 50+ members!**