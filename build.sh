PLUGINS=(markdown-notices
  twig-extensions
  shortcode-gallery-plusplus
  static-generator)
  
cd webroot/grav

# Replace user dir by AFJ's content
rm -rf user
git clone https://github.com/team-afj/grav-user.git user

# Install required plugins
bin/gpm install -y markdown-notices twig-extensions \
  shortcode-gallery-plusplus static-generator

# Generate static version
bin/plugin static-generator page "/" -a -s -i
