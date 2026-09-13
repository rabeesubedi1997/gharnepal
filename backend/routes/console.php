<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Saved-search alerts: 'instant' fires inline from PropertyListingService::
// approve(); these two cover the 'daily'/'weekly' cadences. Needs the
// server's own cron calling `artisan schedule:run` every minute — not set up
// automatically by this command existing (see DEPLOYMENT.md).
Schedule::command('saved-searches:send-digests daily')->dailyAt('08:00');
Schedule::command('saved-searches:send-digests weekly')->weeklyOn(1, '08:00');
