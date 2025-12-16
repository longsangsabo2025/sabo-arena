# Locust Load Testing Scenarios for SABO Arena
# Run with: locust -f locustfile.py --host=https://your-project.supabase.co

from locust import HttpUser, task, between
import os
import json
import random

class SABOArenaUser(HttpUser):
    wait_time = between(1, 3)  # Wait 1-3 seconds between tasks
    
    def on_start(self):
        """Called when a simulated user starts"""
        self.supabase_url = os.getenv('SUPABASE_URL', 'https://your-project.supabase.co')
        self.anon_key = os.getenv('SUPABASE_ANON_KEY', 'your-anon-key')
        self.headers = {
            'apikey': self.anon_key,
            'Authorization': f'Bearer {self.anon_key}',
            'Content-Type': 'application/json',
        }
    
    @task(3)
    def get_tournament_list(self):
        """Get tournament list - most common operation"""
        with self.client.get(
            f"{self.supabase_url}/rest/v1/tournaments?select=*&limit=20",
            headers=self.headers,
            name="Tournament List",
            catch_response=True
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Status code: {response.status_code}")
    
    @task(2)
    def get_user_profile(self):
        """Get user profile"""
        # Use a test user ID or random ID
        user_id = os.getenv('TEST_USER_ID', 'test-user-id')
        with self.client.get(
            f"{self.supabase_url}/rest/v1/profiles?id=eq.{user_id}",
            headers=self.headers,
            name="User Profile",
            catch_response=True
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Status code: {response.status_code}")
    
    @task(1)
    def create_tournament(self):
        """Create tournament - write operation"""
        tournament_data = {
            "name": f"Load Test Tournament {random.randint(1000, 9999)}",
            "status": "draft",
            "start_time": "2025-12-31T00:00:00Z"
        }
        with self.client.post(
            f"{self.supabase_url}/rest/v1/tournaments",
            json=tournament_data,
            headers=self.headers,
            name="Create Tournament",
            catch_response=True
        ) as response:
            if response.status_code in [200, 201]:
                response.success()
            else:
                response.failure(f"Status code: {response.status_code}")
    
    @task(1)
    def get_club_list(self):
        """Get club list"""
        with self.client.get(
            f"{self.supabase_url}/rest/v1/clubs?select=*&limit=20",
            headers=self.headers,
            name="Club List",
            catch_response=True
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Status code: {response.status_code}")
    
    @task(1)
    def get_leaderboard(self):
        """Get leaderboard"""
        with self.client.get(
            f"{self.supabase_url}/rest/v1/profiles?select=*&order=elo_rating.desc&limit=50",
            headers=self.headers,
            name="Leaderboard",
            catch_response=True
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Status code: {response.status_code}")

# Run with:
# locust -f locustfile.py --host=https://your-project.supabase.co --users 1000 --spawn-rate 10

