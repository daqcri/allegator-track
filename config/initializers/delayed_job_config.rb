Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = Rails.env.development? ? 500 : 3
Delayed::Worker.max_attempts = 3
Delayed::Worker.max_run_time = 1.hours
Delayed::Worker.read_ahead = 1
Delayed::Worker.default_queue_name = 'default'
Delayed::Worker.delay_jobs = !Rails.env.test?
Delayed::Worker.raise_signal_exceptions = :term
# so that worker unlocks the job upon SIGTERM so that another worker will pick it up later (heroku)
