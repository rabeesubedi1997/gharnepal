<?php

namespace App\Http\Controllers\Api\V1\Account;

use App\Domain\Identity\Services\OtpService;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class PhoneVerificationController extends Controller
{
    public function __construct(private readonly OtpService $otpService) {}

    public function requestOtp(Request $request): JsonResponse
    {
        $data = $request->validate([
            'phone' => ['required', 'string', 'max:20'],
        ]);

        $this->otpService->requestForUser($request->user(), $data['phone']);

        return response()->json(['message' => 'Verification code sent.']);
    }

    public function verifyOtp(Request $request): JsonResponse
    {
        $data = $request->validate([
            'phone' => ['required', 'string', 'max:20'],
            'code' => ['required', 'string'],
        ]);

        $verified = $this->otpService->verifyForUser($request->user(), $data['phone'], $data['code']);

        if (! $verified) {
            throw ValidationException::withMessages([
                'code' => 'That code is invalid or has expired.',
            ]);
        }

        return response()->json(['message' => 'Phone verified.']);
    }
}
