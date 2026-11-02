import 'ocr_rule_model.dart';
import 'sub_brand_meta.dart';

/// Immutable container of active OCR extraction rules used by PaintLabelExtractor.
class ExtractionRules {
  final Map<String, String> knownBrands;
  final Map<String, SubBrandMeta> knownSubBrands;
  final List<String> brandAndBoilerplate;
  final List<String> paintPrefixes;
  final Set<String> brandTokensToSkip;

  const ExtractionRules({
    required this.knownBrands,
    required this.knownSubBrands,
    required this.brandAndBoilerplate,
    required this.paintPrefixes,
    required this.brandTokensToSkip,
  });

  /// Factory providing default factory rules
  factory ExtractionRules.defaults() => DefaultExtractionRules.createDefault();

  /// Build active rules from a list of OcrRuleModels stored in the database
  factory ExtractionRules.fromRuleModels(List<OcrRuleModel> rules) {
    final Map<String, String> knownBrands = {};
    final Map<String, SubBrandMeta> knownSubBrands = {};
    final List<String> brandAndBoilerplate = [];
    final List<String> paintPrefixes = [];
    final Set<String> brandTokensToSkip = {};

    for (final rule in rules) {
      if (!rule.isActive) continue;
      final token = rule.token.trim().toUpperCase();
      if (token.isEmpty) continue;

      switch (rule.category) {
        case 'brand':
          if (rule.targetValue != null && rule.targetValue!.trim().isNotEmpty) {
            knownBrands[token] = rule.targetValue!.trim();
          }
          break;
        case 'sub_brand':
          final sub = rule.targetValue?.trim() ?? token;
          final parent = rule.parentBrand?.trim() ?? '';
          if (parent.isNotEmpty) {
            knownSubBrands[token] = SubBrandMeta(parent, sub);
          }
          break;
        case 'boilerplate':
          if (!brandAndBoilerplate.contains(token)) {
            brandAndBoilerplate.add(token);
          }
          break;
        case 'paint_prefix':
          if (!paintPrefixes.contains(token)) {
            paintPrefixes.add(token);
          }
          break;
        case 'skip_token':
          brandTokensToSkip.add(token);
          break;
      }
    }

    return ExtractionRules(
      knownBrands: Map.unmodifiable(knownBrands),
      knownSubBrands: Map.unmodifiable(knownSubBrands),
      brandAndBoilerplate: List.unmodifiable(brandAndBoilerplate),
      paintPrefixes: List.unmodifiable(paintPrefixes),
      brandTokensToSkip: Set.unmodifiable(brandTokensToSkip),
    );
  }
}

/// Contains factory-default collections for seed and fallback.
class DefaultExtractionRules {
  static const List<String> defaultBrandAndBoilerplate = [
    'ASIAN PAINTS',
    'PUNJAB PAINT',
    'COLOUR & VARNISH',
    'LIMITED',
    'LTD',
    'REGD. OFFICE',
    'REGD OFFICE',
    'MADAN STREET',
    'SHANTINAGAR',
    'SANTACRUZ',
    'MUMBAI',
    'KOLKATA',
    'WEST BENGAL',
    'MAHARASHTRA',
    'FOR FEEDBACK',
    'COMPLAINTS',
    'CUSTOMERCARE',
    'CENTRICITY MANAGER',
    'LEAD CONTENT',
    'BEST BEFORE',
    'INCL. OF ALL TAXES',
    'INCL.OF ALL TAXES',
    'PER LITRE',
    'PER ML',
    'ADD COLORANTS',
    'COLORANTS COST EXTRA',
    'PAINTS',
    'FOR INDUSTRIAL',
    'STORE IN',
    'KEEP AWAY',
  ];

  static const Map<String, String> defaultKnownBrands = {
    // Asian Paints group
    'ASIAN PAINTS': 'Asian Paints',
    'ASIANPAINTS': 'Asian Paints',
    'APCOLITE': 'Asian Paints',

    // Aditya Birla Group
    'BIRLA OPUS': 'Birla Opus',
    'BIRLAOPUS': 'Birla Opus',
    'BIRLA OPUS PAINTS': 'Birla Opus',
    'OPUS': 'Birla Opus',
    'BIRLA WHITE': 'Birla White',
    'BIRLAWHITE': 'Birla White',

    // Berger Paints group
    'BERGER PAINTS': 'Berger Paints',
    'BERGER': 'Berger Paints',
    'BRITISH PAINTS': 'British Paints',
    'RAJDOOT PAINTS': 'Rajdoot Paints',
    'RAJDOOT': 'Rajdoot Paints',

    // Kansai Nerolac
    'KANSAI NEROLAC': 'Kansai Nerolac',
    'NEROLAC': 'Nerolac',
    'KANSAI': 'Kansai Nerolac',

    // AkzoNobel / Dulux
    'AKZO NOBEL': 'AkzoNobel',
    'AKZONOBEL': 'AkzoNobel',
    'DULUX': 'Dulux',
    'ICI DULUX': 'Dulux',
    'SIKKENS': 'Sikkens',

    // JSW Paints
    'JSW PAINTS': 'JSW Paints',
    'JSW': 'JSW Paints',

    // Indigo Paints
    'INDIGO PAINTS': 'Indigo Paints',
    'INDIGO': 'Indigo Paints',

    // Nippon Paint
    'NIPPON PAINT': 'Nippon Paint',
    'NIPPON': 'Nippon Paint',

    // Shalimar Paints
    'SHALIMAR PAINTS': 'Shalimar Paints',
    'SHALIMAR': 'Shalimar Paints',

    // Sheenlac Paints
    'SHEENLAC PAINTS': 'Sheenlac',
    'SHEENLAC': 'Sheenlac',

    // Sirca Paints
    'SIRCA PAINTS': 'Sirca',
    'SIRCA': 'Sirca',

    // Kamdhenu Paints
    'KAMDHENU PAINTS': 'Kamdhenu Paints',
    'KAMDHENU': 'Kamdhenu Paints',

    // Astral Paints
    'ASTRAL PAINTS': 'Astral Paints',
    'ASTRAL': 'Astral Paints',
    'GEM PAINTS': 'Gem Paints',

    // Snowcem Paints
    'SNOWCEM PAINTS': 'Snowcem',
    'SNOWCEM': 'Snowcem',

    // Jotun Paints
    'JOTUN PAINTS': 'Jotun',
    'JOTUN': 'Jotun',

    // Pidilite / ICA Pidilite
    'ICA PIDILITE': 'ICA Pidilite',
    'PIDILITE': 'Pidilite',
    'DR. FIXIT': 'Dr. Fixit',
    'DR FIXIT': 'Dr. Fixit',
    'ROFF': 'Roff',

    // MRF Corp
    'MRF VAPOCURE': 'MRF Corp',
    'MRF PAINTS': 'MRF Corp',
    'MRF CORP': 'MRF Corp',
    'MRF': 'MRF Corp',

    // Surfa Coats Paints
    'SURFA COATS': 'Surfa Coats',
    'SURFACOATS': 'Surfa Coats',

    // Apollo Paints
    'APOLLO PAINTS': 'Apollo Paints',

    // Sakarni Plasters & Paints
    'SAKARNI PAINTS': 'Sakarni',
    'SAKARNI': 'Sakarni',

    // National Paints
    'NATIONAL PAINTS': 'National Paints',

    // Garware Paints
    'GARWARE PAINTS': 'Garware Paints',
    'GARWARE': 'Garware Paints',

    // Esdee Paints
    'ESDEE PAINTS': 'Esdee Paints',
    'ESDEE': 'Esdee Paints',

    // Grand Polycoats
    'GRAND POLYCOATS': 'Grand Polycoats',

    // Camlin
    'KOKUYO CAMLIN': 'Camlin',
    'CAMLIN': 'Camlin',

    // Specialty
    'MARVEL PAINTS': 'Marvel Paints',
    'VIPUL PAINTS': 'Vipul Paints',
    'RAL': 'RAL',
  };

  static const Map<String, SubBrandMeta> defaultKnownSubBrands = {
    // Asian Paints
    'APCOLITE': SubBrandMeta('Asian Paints', 'Apcolite'),
    'ROYALE': SubBrandMeta('Asian Paints', 'Royale'),
    'APEX': SubBrandMeta('Asian Paints', 'Apex'),
    'APEX ULTIMA': SubBrandMeta('Asian Paints', 'Apex Ultima'),
    'ULTIMA': SubBrandMeta('Asian Paints', 'Apex Ultima'),
    'TRACTOR': SubBrandMeta('Asian Paints', 'Tractor'),
    'TRA EML': SubBrandMeta('Asian Paints', 'Tractor'),
    'ACE': SubBrandMeta('Asian Paints', 'Ace'),
    'SMARTCARE': SubBrandMeta('Asian Paints', 'SmartCare'),
    'DAMPROOF': SubBrandMeta('Asian Paints', 'SmartCare'),
    'WOODTECH': SubBrandMeta('Asian Paints', 'WoodTech'),
    'TRUCARE': SubBrandMeta('Asian Paints', 'TruCare'),
    'APCOFRESH': SubBrandMeta('Asian Paints', 'ApcoFresh'),
    'APCOFRSH': SubBrandMeta('Asian Paints', 'ApcoFresh'),
    'DECOPRIME': SubBrandMeta('Asian Paints', 'DecoPrime'),
    'PGE': SubBrandMeta('Asian Paints', 'PGE Enamel'),

    // Berger Paints
    'WEATHERCOAT': SubBrandMeta('Berger Paints', 'WeatherCoat'),
    'SILK GLAMOR': SubBrandMeta('Berger Paints', 'Silk Glamor'),
    'SILK': SubBrandMeta('Berger Paints', 'Silk'),
    'BISON': SubBrandMeta('Berger Paints', 'Bison'),
    'LUXOL': SubBrandMeta('Berger Paints', 'Luxol'),
    'WALMASTA': SubBrandMeta('Berger Paints', 'Walmasta'),
    'BREATHE EASY': SubBrandMeta('Berger Paints', 'Breathe Easy'),
    'WOODKEEPER': SubBrandMeta('Berger Paints', 'WoodKeeper'),
    'HOMESHIELD': SubBrandMeta('Berger Paints', 'HomeShield'),
    'ILLUSION': SubBrandMeta('Berger Paints', 'Illusion'),
    'RANGOLI': SubBrandMeta('Berger Paints', 'Rangoli'),

    // Kansai Nerolac
    'IMPRESSIONS': SubBrandMeta('Kansai Nerolac', 'Impressions'),
    'EXCEL': SubBrandMeta('Kansai Nerolac', 'Excel'),
    'BEAUTY': SubBrandMeta('Kansai Nerolac', 'Beauty'),
    'SURAKSHA': SubBrandMeta('Kansai Nerolac', 'Suraksha'),
    'SOLDIER': SubBrandMeta('Kansai Nerolac', 'Soldier'),
    'PERMASHIELD': SubBrandMeta('Kansai Nerolac', 'PermaShield'),

    // AkzoNobel / Dulux
    'VELVET TOUCH': SubBrandMeta('Dulux', 'Velvet Touch'),
    'WEATHERSHIELD': SubBrandMeta('Dulux', 'Weathershield'),
    'PROMISE': SubBrandMeta('Dulux', 'Promise'),
    'SIMPLY REFRESH': SubBrandMeta('Dulux', 'Simply Refresh'),
    'SUPERCLEAN': SubBrandMeta('Dulux', 'SuperClean'),
    'AQUATECH': SubBrandMeta('Dulux', 'Aquatech'),
    'DUWEL': SubBrandMeta('Dulux', 'Duwel'),

    // Birla Opus
    'CALISTA': SubBrandMeta('Birla Opus', 'Calista'),
    'STYLE': SubBrandMeta('Birla Opus', 'Style'),
    'PRIME': SubBrandMeta('Birla Opus', 'Prime'),
    'ALLDRY': SubBrandMeta('Birla Opus', 'AllDry'),
    'ALLWOOD': SubBrandMeta('Birla Opus', 'AllWood'),
    'ONE': SubBrandMeta('Birla Opus', 'One'),

    // JSW Paints
    'HALO': SubBrandMeta('JSW Paints', 'Halo'),
    'AURUS': SubBrandMeta('JSW Paints', 'Aurus'),
    'PIXA': SubBrandMeta('JSW Paints', 'Pixa'),

    // Nippon Paint
    'WEATHERBOND': SubBrandMeta('Nippon Paint', 'Weatherbond'),
    'SPOTLESS': SubBrandMeta('Nippon Paint', 'Spotless'),
    'SATIN GLO': SubBrandMeta('Nippon Paint', 'Satin Glo'),
    'BREEZE': SubBrandMeta('Nippon Paint', 'Breeze'),
    'SUMO': SubBrandMeta('Nippon Paint', 'Sumo'),
    'BODELAC': SubBrandMeta('Nippon Paint', 'Bodelac'),
    'AIRCARE': SubBrandMeta('Nippon Paint', 'AirCare'),
    'MATEX': SubBrandMeta('Nippon Paint', 'Matex'),

    // Indigo Paints
    'BRIGHT CEILING': SubBrandMeta('Indigo Paints', 'Bright Ceiling Coat'),
    'DIRTPROOF': SubBrandMeta('Indigo Paints', 'Dirtproof'),
    'FLOOR COAT': SubBrandMeta('Indigo Paints', 'Floor Coat'),
    'TILE COAT': SubBrandMeta('Indigo Paints', 'Tile Coat'),

    // British Paints
    'SHINGLE': SubBrandMeta('British Paints', 'Shingle'),
    'GLAMOUR': SubBrandMeta('British Paints', 'Glamour'),
    'ACRI-SILK': SubBrandMeta('British Paints', 'Acri-Silk'),
    'STAINGARD': SubBrandMeta('British Paints', 'Staingard'),
    'EXPA COOL': SubBrandMeta('British Paints', 'Expa Cool'),

    // Shalimar Paints
    'SUPERLAC': SubBrandMeta('Shalimar Paints', 'Superlac'),
    'WEATHER PRO': SubBrandMeta('Shalimar Paints', 'Weather Pro'),
    'SIGNATURE': SubBrandMeta('Shalimar Paints', 'Signature'),
    'SHAKTIMAN': SubBrandMeta('Shalimar Paints', 'Shaktiman'),

    // MRF Corp
    'VAPOCURE': SubBrandMeta('MRF Corp', 'Vapocure'),
    'WOODCOAT': SubBrandMeta('MRF Corp', 'WoodCoat'),
    'METALCOAT': SubBrandMeta('MRF Corp', 'MetalCoat'),

    // Pidilite
    'DR. FIXIT': SubBrandMeta('Pidilite', 'Dr. Fixit'),
    'DR FIXIT': SubBrandMeta('Pidilite', 'Dr. Fixit'),
    'ROFF': SubBrandMeta('Pidilite', 'Roff'),
  };

  static const List<String> defaultPaintPrefixes = [
    'PGE',
    'APEX',
    'TRA EML',
    'TRACTOR',
    'APCOFRESH',
    'APCOFRSH',
    'APCOLITE',
    'SATIN EN',
    'SATIN',
    'ROYALE',
    'ACE',
    'TRUCARE',
    'DAMPROOF',
    'SMARTCARE',
    'ULTIMA',
    'SM GRY',
    'SNDSTN',
    'WOODTECH',
    'CALISTA',
    'WEATHERCOAT',
    'SILK GLAMOR',
    'SILK',
    'BISON',
    'IMPRESSIONS',
    'EXCEL',
    'WEATHERSHIELD',
    'VELVET TOUCH',
    'AURUS',
    'HALO',
    'PIXA',
    'PU',
    'ENAMEL',
    'EMULSION',
    'DISTEMPER',
    'LUSTRE',
    'WALL PRIMER',
    'PRIMER',
  ];

  static const Set<String> defaultBrandTokensToSkip = {
    'ASIAN PAINTS',
    'ASIANPAINTS',
    'BIRLA OPUS',
    'BIRLAOPUS',
    'OPUS',
    'BIRLA WHITE',
    'BERGER',
    'BRITISH PAINTS',
    'NEROLAC',
    'KANSAI NEROLAC',
    'KANSAI',
    'DULUX',
    'AKZONOBEL',
    'JSW PAINTS',
    'JSW',
    'NIPPON',
    'NIPPON PAINT',
    'INDIGO',
    'INDIGO PAINTS',
    'JOTUN',
    'SHALIMAR',
    'SHEENLAC',
    'SNOWCEM',
    'KAMDHENU',
    'SIRCA',
    'ASTRAL',
    'PIDILITE',
    'CAMLIN',
    'GARWARE',
    'ESDEE',
    'SAKARNI',
  };

  static ExtractionRules createDefault() {
    return const ExtractionRules(
      knownBrands: defaultKnownBrands,
      knownSubBrands: defaultKnownSubBrands,
      brandAndBoilerplate: defaultBrandAndBoilerplate,
      paintPrefixes: defaultPaintPrefixes,
      brandTokensToSkip: defaultBrandTokensToSkip,
    );
  }

  /// Generate seed models for database initialization
  static List<OcrRuleModel> generateSeedModels() {
    final now = DateTime.now();
    final List<OcrRuleModel> list = [];

    // Brands
    defaultKnownBrands.forEach((token, canonical) {
      list.add(OcrRuleModel(
        category: 'brand',
        token: token,
        targetValue: canonical,
        isCustom: false,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ));
    });

    // Sub-brands
    defaultKnownSubBrands.forEach((token, meta) {
      list.add(OcrRuleModel(
        category: 'sub_brand',
        token: token,
        targetValue: meta.subBrand,
        parentBrand: meta.parentBrand,
        isCustom: false,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ));
    });

    // Boilerplate
    for (final token in defaultBrandAndBoilerplate) {
      list.add(OcrRuleModel(
        category: 'boilerplate',
        token: token,
        isCustom: false,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ));
    }

    // Paint prefixes
    for (final prefix in defaultPaintPrefixes) {
      list.add(OcrRuleModel(
        category: 'paint_prefix',
        token: prefix,
        isCustom: false,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ));
    }

    // Skip tokens
    for (final skip in defaultBrandTokensToSkip) {
      list.add(OcrRuleModel(
        category: 'skip_token',
        token: skip,
        isCustom: false,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ));
    }

    return list;
  }
}

