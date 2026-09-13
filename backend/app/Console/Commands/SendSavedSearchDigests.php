<?php

namespace App\Console\Commands;

use App\Domain\Engagement\Services\SavedSearchAlertService;
use Illuminate\Console\Command;

/**
 * Instant alerts fire from PropertyListingService::approve() the moment a
 * listing goes live; this covers the other two `alert_frequency` cadences
 * ('daily'/'weekly'), scheduled in routes/console.php.
 */
class SendSavedSearchDigests extends Command
{
    protected $signature = 'saved-searches:send-digests {frequency : daily or weekly}';

    protected $description = 'Email a digest of new matching listings to saved searches due for a daily or weekly alert.';

    public function handle(SavedSearchAlertService $alerts): int
    {
        $frequency = $this->argument('frequency');

        if (! in_array($frequency, ['daily', 'weekly'], true)) {
            $this->error("Frequency must be 'daily' or 'weekly', got '{$frequency}'.");

            return self::FAILURE;
        }

        $sent = $alerts->sendDueDigests($frequency);
        $this->info("Sent {$sent} {$frequency} saved-search digest(s).");

        return self::SUCCESS;
    }
}
