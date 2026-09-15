<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

/**
 * Self-serve SMTP diagnosis: an admin who just set MAIL_* in the live .env
 * has no way to know whether it actually works without waiting for a real
 * alert to (not) arrive. This sends one real email right now — to whatever
 * address the admin types in, defaulting to their own — and reports
 * success/failure, including the raw transport error (safe: admin-only,
 * and it's exactly what's needed to fix a bad host/port/credential)
 * instead of a silent miss.
 */
class MailTestController extends Controller
{
    public function send(Request $request): JsonResponse
    {
        $data = $request->validate(['to' => ['nullable', 'email', 'max:255']]);
        $to = $data['to'] ?? $request->user()->email;
        $mailer = config('mail.default');

        try {
            Mail::raw(
                'This is a test email from the Ghar Nepal admin panel, sent '.now()->toDayDateTimeString().
                ". If you received this, outbound email (mailer: {$mailer}) is working correctly.",
                fn ($message) => $message->to($to)->subject('Ghar Nepal — test email'),
            );

            return response()->json(['data' => ['sent' => true, 'to' => $to, 'mailer' => $mailer, 'error' => null]]);
        } catch (\Throwable $e) {
            Log::warning('Admin-triggered test email failed', ['error' => $e->getMessage()]);

            return response()->json(['data' => ['sent' => false, 'to' => $to, 'mailer' => $mailer, 'error' => $e->getMessage()]]);
        }
    }
}
