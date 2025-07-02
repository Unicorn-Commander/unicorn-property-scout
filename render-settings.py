#!/usr/bin/env python3
"""
SearXNG Settings Template Renderer
Reads values from .env file and renders the settings.yml.template into settings.yml
"""

from jinja2 import Environment, FileSystemLoader
from dotenv import dotenv_values
import os
import sys

def render_template():
    """Render the settings.yml template using environment variables"""
    try:
        # Get the directory of this script
        script_dir = os.path.dirname(os.path.abspath(__file__))
        
        # Load .env values (look in parent directory if not in current)
        env_path = os.path.join(os.path.dirname(script_dir), '.env')
        if not os.path.exists(env_path):
            env_path = os.path.join(script_dir, '.env')
        
        if not os.path.exists(env_path):
            print(f"Error: .env file not found at {env_path}")
            sys.exit(1)
            
        env_vars = dotenv_values(env_path)
        
        # Also include actual environment variables (in case some were passed directly)
        for key, value in os.environ.items():
            env_vars[key] = value
        
        # Check for required variables
        required_vars = ["SEARXNG_SECRET", "SEARXNG_REDIS_URL"]
        missing_vars = [var for var in required_vars if env_vars.get(var) is None]
        
        if missing_vars:
            print(f"Error: Missing required environment variables: {', '.join(missing_vars)}")
            sys.exit(1)
        
        # Check if template file exists
        template_path = os.path.join(script_dir, "settings.yml.template")
        if not os.path.exists(template_path):
            print(f"Error: Template file not found at {template_path}")
            sys.exit(1)
        
        # Render settings.yml from settings.yml.template
        print("Rendering settings.yml from template...")
        env = Environment(loader=FileSystemLoader(os.path.dirname(template_path)), 
                          trim_blocks=True, 
                          lstrip_blocks=True)
        template = env.get_template(os.path.basename(template_path))
        
        # Convert string values like "true" to Python bool
        for key in env_vars:
            if isinstance(env_vars[key], str):
                if env_vars[key].lower() == "true":
                    env_vars[key] = True
                elif env_vars[key].lower() == "false":
                    env_vars[key] = False
        
        rendered = template.render(**env_vars)
        
        # Write to settings.yml
        output_path = os.path.join(script_dir, "settings.yml")
        with open(output_path, "w") as f:
            f.write(rendered)
        
        print(f"Successfully generated {output_path}")
        return True
    
    except Exception as e:
        print(f"Error rendering template: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    render_template()
