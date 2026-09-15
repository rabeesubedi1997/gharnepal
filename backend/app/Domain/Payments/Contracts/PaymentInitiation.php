<?php

namespace App\Domain\Payments\Contracts;

/**
 * Everything the frontend needs to actually get the buyer to (or through)
 * a gateway, in one small, provider-agnostic shape:
 *
 *  - 'inline'    — sandbox/manual: no external redirect at all, the buyer
 *                  stays on our own page (a "simulate" button, or payment
 *                  instructions to follow).
 *  - 'redirect'  — a plain GET to `redirect_url` (Khalti, PayPal: they hand
 *                  back a ready-made URL to send the browser to).
 *  - 'form_post' — the frontend must build a real HTML <form method="POST">
 *                  to `redirect_url` with `form_fields` as hidden inputs and
 *                  submit it (eSewa's v2 API requires a signed POST, not a
 *                  GET link — a query string can't carry it correctly).
 */
final class PaymentInitiation
{
    /** @param array<string,string> $formFields */
    public function __construct(
        public readonly string $mode,
        public readonly ?string $redirectUrl = null,
        public readonly array $formFields = [],
        public readonly ?string $instructions = null,
    ) {}

    public static function inline(?string $instructions = null): self
    {
        return new self('inline', instructions: $instructions);
    }

    public static function redirect(string $url): self
    {
        return new self('redirect', redirectUrl: $url);
    }

    /** @param array<string,string> $fields */
    public static function formPost(string $url, array $fields): self
    {
        return new self('form_post', redirectUrl: $url, formFields: $fields);
    }
}
