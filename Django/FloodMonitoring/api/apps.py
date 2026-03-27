from django.apps import AppConfig

# This file defines the configuration for the 'api' app. It also sets up a background scheduler to periodically fetch data from Blynk sensors every 5 minutes using APScheduler. The scheduler is started when the Django application is ready, ensuring that the data fetching task runs in the background without blocking the main application.
class ApiConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'api'

    def ready(self):
        from apscheduler.schedulers.background import BackgroundScheduler
        from .tasks import fetch_all_blynk_data
        import os

        # Only start the scheduler if we're running the main process (to avoid multiple schedulers in development with auto-reload)
        if os.environ.get('RUN_MAIN') == 'true':
            scheduler = BackgroundScheduler()
            scheduler.add_job(fetch_all_blynk_data, 'interval', minutes=5) #minutes=5 means it will run every 5 minutes
            scheduler.start()
            print("--- Background Scheduler Started ---")