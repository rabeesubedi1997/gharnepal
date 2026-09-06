<?php

namespace App\Domain\Identity\Contracts;

interface OtpSender
{
    public function send(string $phone, string $code): void;
}
