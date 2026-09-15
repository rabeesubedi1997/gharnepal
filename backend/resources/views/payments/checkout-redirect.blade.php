<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Redirecting to payment…</title>
    <style>
        body { font-family: system-ui, -apple-system, sans-serif; display: flex; min-height: 100vh; align-items: center; justify-content: center; margin: 0; background: #f7f5f2; color: #1f2933; }
        .box { text-align: center; padding: 24px; }
        button { margin-top: 16px; padding: 10px 20px; font-size: 15px; border-radius: 8px; border: none; background: #0f5b52; color: #fff; }
    </style>
</head>
<body>
    <div class="box">
        <p>Redirecting you to your payment provider…</p>
        <form id="checkout-form" method="POST" action="{{ $url }}">
            @foreach ($fields as $key => $value)
                <input type="hidden" name="{{ $key }}" value="{{ $value }}">
            @endforeach
            <noscript>
                <button type="submit">Continue to payment</button>
            </noscript>
        </form>
    </div>
    <script>document.getElementById('checkout-form').submit();</script>
</body>
</html>
