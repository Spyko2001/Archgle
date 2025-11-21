#!/usr/bin/env python3
"""
Archgle AI Daemon - System-level AI integration using Gemini API
Provides AI-assisted system management, automation, and troubleshooting
"""

import os
import sys
import json
import time
import logging
import subprocess
import threading
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional

# Google API imports
try:
    import google.auth
    from google.auth.transport.requests import Request
    from google.oauth2.credentials import Credentials
    from google_auth_oauthlib.flow import InstalledAppFlow
    import requests
except ImportError:
    print("Error: Required Python packages not installed")
    print("Install with: pip install google-auth google-auth-oauthlib google-auth-httplib2 requests")
    sys.exit(1)

# Configuration
CONFIG_DIR = Path.home() / ".config" / "archgle-ai"
TOKEN_FILE = CONFIG_DIR / "token.json"
CREDENTIALS_FILE = CONFIG_DIR / "credentials.json"
LOG_FILE = "/var/log/archgle-ai-daemon.log"
SCOPES = [
    'https://www.googleapis.com/auth/userinfo.email',
    'https://www.googleapis.com/auth/userinfo.profile',
    'openid'
]

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger('archgle-ai')


class ArchgleAI:
    """Main AI daemon class"""
    
    def __init__(self):
        self.running = False
        self.credentials = None
        self.gemini_api_key = None
        self.user_email = None
        CONFIG_DIR.mkdir(parents=True, exist_ok=True)
        
    def authenticate(self) -> bool:
        """Authenticate with Google account or API key"""
        
        # Try Google OAuth first
        if self._authenticate_google():
            logger.info(f"Authenticated with Google account: {self.user_email}")
            return True
            
        # Fall back to API key
        if self._authenticate_api_key():
            logger.info("Authenticated with Gemini API key")
            return True
            
        logger.error("Authentication failed - no valid credentials found")
        return False
    
    def _authenticate_google(self) -> bool:
        """Authenticate using Google OAuth"""
        try:
            # Load existing token
            if TOKEN_FILE.exists():
                self.credentials = Credentials.from_authorized_user_file(str(TOKEN_FILE), SCOPES)
            
            # Refresh or get new token
            if not self.credentials or not self.credentials.valid:
                if self.credentials and self.credentials.expired and self.credentials.refresh_token:
                    self.credentials.refresh(Request())
                elif CREDENTIALS_FILE.exists():
                    flow = InstalledAppFlow.from_client_secrets_file(str(CREDENTIALS_FILE), SCOPES)
                    self.credentials = flow.run_local_server(port=0)
                else:
                    return False
                
                # Save token
                with open(TOKEN_FILE, 'w') as token:
                    token.write(self.credentials.to_json())
            
            # Get user info
            user_info = self._get_user_info()
            if user_info:
                self.user_email = user_info.get('email')
                return True
                
        except Exception as e:
            logger.error(f"Google authentication error: {e}")
            
        return False
    
    def _authenticate_api_key(self) -> bool:
        """Authenticate using Gemini API key"""
        # Check environment variable
        api_key = os.getenv('GEMINI_API_KEY')
        
        # Check config file
        if not api_key:
            api_key_file = CONFIG_DIR / "api_key.txt"
            if api_key_file.exists():
                api_key = api_key_file.read_text().strip()
        
        if api_key:
            self.gemini_api_key = api_key
            return True
            
        return False
    
    def _get_user_info(self) -> Optional[Dict]:
        """Get user information from Google"""
        if not self.credentials:
            return None
            
        try:
            response = requests.get(
                'https://www.googleapis.com/oauth2/v1/userinfo',
                headers={'Authorization': f'Bearer {self.credentials.token}'}
            )
            if response.status_code == 200:
                return response.json()
        except Exception as e:
            logger.error(f"Error getting user info: {e}")
            
        return None
    
    def call_gemini(self, prompt: str, context: Optional[Dict] = None) -> Optional[str]:
        """Call Gemini API with prompt"""
        if not self.gemini_api_key and not self.credentials:
            logger.error("No valid authentication for Gemini API")
            return None
        
        # TODO: Implement actual Gemini API call
        # This is a placeholder - actual implementation will use the Gemini API endpoint
        logger.info(f"Gemini API call: {prompt[:100]}...")
        
        # For now, return a placeholder response
        return "Gemini API integration pending - authentication successful"
    
    def monitor_system(self):
        """Monitor system events and logs"""
        logger.info("Starting system monitoring...")
        
        while self.running:
            try:
                # Monitor system metrics
                cpu_usage = self._get_cpu_usage()
                mem_usage = self._get_memory_usage()
                disk_usage = self._get_disk_usage()
                
                # Log metrics
                logger.debug(f"System: CPU={cpu_usage}% MEM={mem_usage}% DISK={disk_usage}%")
                
                # Check for anomalies
                if cpu_usage > 90:
                    logger.warning(f"High CPU usage detected: {cpu_usage}%")
                if mem_usage > 90:
                    logger.warning(f"High memory usage detected: {mem_usage}%")
                
                time.sleep(30)  # Monitor every 30 seconds
                
            except Exception as e:
                logger.error(f"Monitoring error: {e}")
                time.sleep(60)
    
    def _get_cpu_usage(self) -> float:
        """Get CPU usage percentage"""
        try:
            output = subprocess.check_output(['top', '-bn1']).decode()
            for line in output.split('\n'):
                if 'Cpu(s)' in line:
                    idle = float(line.split()[7].replace('%id,', ''))
                    return round(100 - idle, 1)
        except:
            pass
        return 0.0
    
    def _get_memory_usage(self) -> float:
        """Get memory usage percentage"""
        try:
            with open('/proc/meminfo') as f:
                lines = f.readlines()
                total = int([l for l in lines if 'MemTotal' in l][0].split()[1])
                available = int([l for l in lines if 'MemAvailable' in l][0].split()[1])
                return round((1 - available/total) * 100, 1)
        except:
            pass
        return 0.0
    
    def _get_disk_usage(self) -> float:
        """Get root disk usage percentage"""
        try:
            output = subprocess.check_output(['df', '-h', '/']).decode()
            usage = output.split('\n')[1].split()[4].replace('%', '')
            return float(usage)
        except:
            pass
        return 0.0
    
    def optimize_system(self) -> bool:
        """AI-driven system optimization"""
        logger.info("Running AI-driven system optimization...")
        
        # Get system info
        system_info = {
            'cpu': self._get_cpu_usage(),
            'memory': self._get_memory_usage(),
            'disk': self._get_disk_usage()
        }
        
        # Ask AI for optimization suggestions
        prompt = f"Analyze this Linux system and suggest optimizations: {json.dumps(system_info)}"
        suggestions = self.call_gemini(prompt, context=system_info)
        
        if suggestions:
            logger.info(f"AI suggestions: {suggestions}")
            return True
            
        return False
    
    def troubleshoot(self, issue: str) -> Optional[str]:
        """AI-assisted troubleshooting"""
        logger.info(f"Troubleshooting: {issue}")
        
        # Gather system context
        context = {
            'issue': issue,
            'system_logs': self._get_recent_logs(),
            'system_info': self._get_system_info()
        }
        
        # Ask AI for help
        prompt = f"Help troubleshoot this Linux system issue: {issue}"
        solution = self.call_gemini(prompt, context=context)
        
        return solution
    
    def _get_recent_logs(self, lines: int = 50) -> List[str]:
        """Get recent system logs"""
        try:
            output = subprocess.check_output(['journalctl', '-n', str(lines), '--no-pager']).decode()
            return output.split('\n')
        except:
            return []
    
    def _get_system_info(self) -> Dict:
        """Get system information"""
        info = {}
        try:
            info['kernel'] = subprocess.check_output(['uname', '-r']).decode().strip()
            info['os'] = 'Archgle Linux'
            info['uptime'] = subprocess.check_output(['uptime', '-p']).decode().strip()
        except:
            pass
        return info
    
    def start(self):
        """Start the AI daemon"""
        logger.info("Starting Archgle AI Daemon...")
        
        if not self.authenticate():
            logger.error("Authentication failed - daemon cannot start")
            return False
        
        self.running = True
        
        # Start monitoring in background thread
        monitor_thread = threading.Thread(target=self.monitor_system, daemon=True)
        monitor_thread.start()
        
        logger.info("Archgle AI Daemon started successfully")
        
        # Keep daemon running
        try:
            while self.running:
                time.sleep(1)
        except KeyboardInterrupt:
            logger.info("Shutting down...")
            self.running = False
        
        return True


def main():
    """Main entry point"""
    daemon = ArchgleAI()
    daemon.start()


if __name__ == "__main__":
    main()
