<?php

namespace App\Domain\Identity\Services;

use App\Domain\Identity\Contracts\OtpSender;
use App\Domain\Trust\Services\TrustScoreCalculator;
use App\Models\PhoneOtp;
use App\Models\PropertyListing;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class OtpService
{
    private const CODE_LENGTH = 6;

    private const EXPIRES_IN_MINUTES = 10;

    private const MAX_ATTEMPTS = 5;

    public function __construct(
        private readonly OtpSender $sender,
        private readonly TrustScoreCalculator $trustScoreCalculator,
    ) {}

    public function requestForUser(User $user, string $phone): void
    {
        $code = (string) random_int(10 ** (self::CODE_LENGTH - 1), (10 ** self::CODE_LENGTH) - 1);

        PhoneOtp::create([
            'user_id' => $user->id,
            'phone' => $phone,
            'code' => Hash::make($code),
            'expires_at' => now()->addMinutes(self::EXPIRES_IN_MINUTES),
        ]);

        $this->sender->send($phone, $code);
    }

    /**
     * @return bool true if the code was valid and the phone is now verified.
     */
    public function verifyForUser(User $user, string $phone, string $code): bool
    {
        $otp = PhoneOtp::query()
            ->where('user_id', $user->id)
            ->where('phone', $phone)
            ->whereNull('consumed_at')
            ->latest('id')
            ->first();

        if (! $otp || $otp->isExpired() || $otp->attempts >= self::MAX_ATTEMPTS) {
            return false;
        }

        if (! Hash::check($code, $otp->code)) {
            $otp->increment('attempts');

            return false;
        }

        $otp->forceFill(['consumed_at' => now()])->save();

        $user->forceFill([
            'phone' => $phone,
            'phone_verified_at' => now(),
        ])->save();

        PropertyListing::query()
            ->where('status', PropertyListing::STATUS_PUBLISHED)
            ->whereHas('property', fn ($q) => $q->where('owner_user_id', $user->id))
            ->get()
            ->each(fn (PropertyListing $listing) => $this->trustScoreCalculator->recompute($listing));

        return true;
    }
}
