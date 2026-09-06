<?php

namespace Database\Seeders;

use App\Models\Banner;
use Illuminate\Database\Seeder;

/**
 * Homepage slider demo content — reuses the same stock photos downloaded
 * for DemoDataSeeder (backend/storage/app/public/demo/) rather than
 * uploading new files. Safe to re-run: keyed on title.
 */
class BannerDemoDataSeeder extends Seeder
{
    public function run(): void
    {
        $banners = [
            [
                'title' => 'Verified Listings Across Nepal',
                'subtitle' => 'Browse trust-scored properties in Kathmandu, Pokhara, Chitwan, and Biratnagar.',
                'image_path' => 'demo/house-exterior-1.jpg',
                'link_url' => '/search',
                'cta_label' => 'Browse listings',
                'sort_order' => 0,
            ],
            [
                'title' => 'Post Your Property in Minutes',
                'subtitle' => 'Reach verified buyers and renters with a trust-scored listing.',
                'image_path' => 'demo/apartment-building-2.jpg',
                'link_url' => '/post-property',
                'cta_label' => 'Get started',
                'sort_order' => 1,
            ],
            [
                'title' => 'Find a Verified Agent',
                'subtitle' => 'Work with agencies reviewed and verified by our admin team.',
                'image_path' => 'demo/office-space-1.jpg',
                'link_url' => '/agents',
                'cta_label' => 'Meet our agents',
                'sort_order' => 2,
            ],
        ];

        foreach ($banners as $banner) {
            Banner::query()->updateOrCreate(
                ['title' => $banner['title']],
                [...$banner, 'is_active' => true],
            );
        }
    }
}
