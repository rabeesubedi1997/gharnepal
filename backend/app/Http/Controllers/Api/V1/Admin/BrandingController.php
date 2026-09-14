<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\BrandingResource;
use App\Models\PlatformBranding;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

/**
 * Read is open to any admin; the actual write is reserved to a super admin
 * (see routes/api.php's `super_admin` middleware on the PUT route) — site
 * branding is exactly the kind of "everyone can see it, only the top tier
 * can change it" setting the rest of the super-admin guard already covers
 * (payment refunds, role grants).
 */
class BrandingController extends Controller
{
    public function show(): BrandingResource
    {
        return new BrandingResource(PlatformBranding::current());
    }

    public function update(Request $request): BrandingResource
    {
        $data = $request->validate([
            'site_name' => ['sometimes', 'string', 'max:100'],
            // Square, simple images only — a favicon or app icon with a
            // transparent/odd aspect ratio renders badly as a launcher icon.
            'favicon' => ['sometimes', 'file', 'image', 'mimes:png,ico,svg,webp', 'max:1024'],
            'app_icon' => ['sometimes', 'file', 'image', 'mimes:png,jpg,jpeg', 'max:5120'],
        ]);

        $branding = PlatformBranding::current();

        if ($request->hasFile('favicon')) {
            if ($branding->favicon_path) {
                Storage::disk('public')->delete($branding->favicon_path);
            }
            $data['favicon_path'] = $request->file('favicon')->store('branding', 'public');
        }

        if ($request->hasFile('app_icon')) {
            if ($branding->app_icon_path) {
                Storage::disk('public')->delete($branding->app_icon_path);
            }
            $data['app_icon_path'] = $request->file('app_icon')->store('branding', 'public');
        }

        $branding->update(collect($data)->except(['favicon', 'app_icon'])->all());

        return new BrandingResource($branding->fresh());
    }
}
