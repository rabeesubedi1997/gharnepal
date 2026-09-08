/// The only 3 valid `placement` values for an `Advertisement`. Immutable
/// after creation — the edit form omits it entirely.
class AdPlacement {
  AdPlacement._();

  static const homeBeforeFooter = 'home_before_footer';
  static const searchSidebar = 'search_sidebar';
  static const listingDetailSidebar = 'listing_detail_sidebar';

  static const values = [homeBeforeFooter, searchSidebar, listingDetailSidebar];

  static String label(String key) => switch (key) {
    homeBeforeFooter => 'Homepage — above the footer',
    searchSidebar => 'Search results — sidebar',
    listingDetailSidebar => 'Listing detail — sidebar',
    _ => key,
  };
}
