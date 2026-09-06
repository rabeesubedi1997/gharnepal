<?php

namespace App\Domain\Identity\Services;

use App\Domain\Identity\Contracts\OtpSender;
use Illuminate\Support\Facades\Log;

/**
 * Interim OTP "sender" for local development: writes the code to the log
 * instead of dispatching a real SMS. No Nepali SMS gateway (e.g. Sparrow SMS,
 * NTC/Ncell bulk SMS) is wired up yet — swapping this for a real one later is
 * a single class behind the OtpSender contract, nothing else changes.
 */
class LogOtpSender implements OtpSender
{
    public function send(string $phone, string $code): void
    {
        Log::info("[dev-only] OTP for {$phone}: {$code}");
    }
}
