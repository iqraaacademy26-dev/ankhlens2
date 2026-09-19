/// A Gardiner sign-list category (e.g. "G" = birds), used for the
/// dictionary's category filter chips.
class GardinerCategory {
  final String code;
  final String label;
  const GardinerCategory(this.code, this.label);
}

/// Starter category list covering the most tourist-relevant Gardiner sign
/// categories. This is NOT the full scholarly A–Aa list — extend as dictionary
/// content grows and as an Egyptology consultant reviews coverage.
const List<GardinerCategory> gardinerCategories = [
  GardinerCategory('A', 'Man and Occupations'),
  GardinerCategory('B', 'Woman'),
  GardinerCategory('C', 'Anthropomorphic Deities'),
  GardinerCategory('D', 'Parts of the Human Body'),
  GardinerCategory('E', 'Mammals'),
  GardinerCategory('G', 'Birds'),
  GardinerCategory('H', 'Parts of Birds'),
  GardinerCategory('I', 'Reptiles & Amphibians'),
  GardinerCategory('K', 'Fish'),
  GardinerCategory('L', 'Invertebrates & Lesser Animals'),
  GardinerCategory('M', 'Trees & Plants'),
  GardinerCategory('N', 'Sky, Earth, Water'),
  GardinerCategory('O', 'Buildings & Parts'),
  GardinerCategory('Q', 'Furniture'),
  GardinerCategory('R', 'Temple & Sacred Emblems'),
  GardinerCategory('S', 'Crowns, Dress, Staves'),
  GardinerCategory('T', 'Warfare, Hunting, Butchery'),
  GardinerCategory('U', 'Agriculture, Crafts, Trades'),
  GardinerCategory('V', 'Rope, Fiber, Baskets'),
  GardinerCategory('W', 'Vessels of Stone & Earthenware'),
  GardinerCategory('X', 'Bread & Cake'),
  GardinerCategory('Y', 'Writing, Games, Music'),
  GardinerCategory('Z', 'Strokes, Geometric Figures'),
];
