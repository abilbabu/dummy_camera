import '../models/paint_label_data.dart';

/// Metadata pairing a paint sub-brand/product line with its parent manufacturer brand.
class _SubBrandMeta {
  final String parentBrand;
  final String subBrand;

  const _SubBrandMeta(this.parentBrand, this.subBrand);
}

/// Intelligent field extractor for paint carton boxes and bucket labels (Amazon Textract style).
/// Extracts ONLY the critical structured data while filtering out background boilerplate.
class PaintLabelExtractor {
  // Regex for Pack Quantity (e.g., "4Nos. X 4L NET", "8Nos. x 500ml NET", "20L NET", "10L NET", "1L HET")
  static final RegExp _packQtyRegex = RegExp(
    r'(\d+\s*(?:Nos?\.?)?\s*[xX*]\s*[\d.]+\s*(?:ml|l|litre|liter|ltr)(?:\s*(?:NET|HET))?|[\d.]+\s*(?:ml|l|litre|liter|ltr)(?:\s*(?:NET|HET))?|\b\d+(?:\.\d+)?\s*(?:ml|l|litre|liter|ltr)\b)',
    caseSensitive: false,
  );

  // Regex for Manufacturing Date (e.g., "Mfd 02/2026", "Mfd 08/2026", "Mfd: 07/2026", "I1fd 082026")
  static final RegExp _mfdRegex = RegExp(
    r'(?:Mfd|Mfg|Manufactured|Pkd|Packed|[I1l]1?fd)\s*[:.-]?\s*([0-9]{1,2}[/-]?[0-9]{2,4})',
    caseSensitive: false,
  );

  // Regex for Batch Number (e.g., "B.No. M2282", "B.No. S1278", "BATCH NO: K665")
  static final RegExp _batchRegex = RegExp(
    r'(?:B\.?\s*No\.?|Batch(?:\s*No\.?)?)\s*[:.-]?\s*([A-Za-z0-9]+)',
    caseSensitive: false,
  );

  // Brand and legal words to strictly filter OUT (never consider as Paint Name)
  static final List<String> _brandAndBoilerplate = [
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

  /// Known paint brand names with their canonical display form.
  /// Key: uppercase token(s) to match in OCR text.
  /// Value: canonical brand display name.
  /// NOTE: Sub-brands like APCOFRESH, APEX, ROYALE are product lines — do NOT list here.
  static final Map<String, String> _knownBrands = {
    // ── Asian Paints group ──────────────────────────────────────────
    'ASIAN PAINTS': 'Asian Paints',
    'ASIANPAINTS': 'Asian Paints',
    'APCOLITE': 'Asian Paints',

    // ── Aditya Birla Group (Birla Opus & Birla White) ──────────────
    'BIRLA OPUS': 'Birla Opus',
    'BIRLAOPUS': 'Birla Opus',
    'BIRLA OPUS PAINTS': 'Birla Opus',
    'OPUS': 'Birla Opus',
    'BIRLA WHITE': 'Birla White',
    'BIRLAWHITE': 'Birla White',

    // ── Berger Paints group ─────────────────────────────────────────
    'BERGER PAINTS': 'Berger Paints',
    'BERGER': 'Berger Paints',
    'BRITISH PAINTS': 'British Paints',
    'RAJDOOT PAINTS': 'Rajdoot Paints',
    'RAJDOOT': 'Rajdoot Paints',

    // ── Kansai Nerolac ─────────────────────────────────────────────
    'KANSAI NEROLAC': 'Kansai Nerolac',
    'NEROLAC': 'Nerolac',
    'KANSAI': 'Kansai Nerolac',

    // ── AkzoNobel / Dulux ──────────────────────────────────────────
    'AKZO NOBEL': 'AkzoNobel',
    'AKZONOBEL': 'AkzoNobel',
    'DULUX': 'Dulux',
    'ICI DULUX': 'Dulux',
    'SIKKENS': 'Sikkens',

    // ── JSW Paints ─────────────────────────────────────────────────
    'JSW PAINTS': 'JSW Paints',
    'JSW': 'JSW Paints',

    // ── Indigo Paints ──────────────────────────────────────────────
    'INDIGO PAINTS': 'Indigo Paints',
    'INDIGO': 'Indigo Paints',

    // ── Nippon Paint ───────────────────────────────────────────────
    'NIPPON PAINT': 'Nippon Paint',
    'NIPPON': 'Nippon Paint',

    // ── Shalimar Paints ────────────────────────────────────────────
    'SHALIMAR PAINTS': 'Shalimar Paints',
    'SHALIMAR': 'Shalimar Paints',

    // ── Sheenlac Paints ────────────────────────────────────────────
    'SHEENLAC PAINTS': 'Sheenlac',
    'SHEENLAC': 'Sheenlac',

    // ── Sirca Paints (Wood & Luxury Wall Finishes) ──────────────────
    'SIRCA PAINTS': 'Sirca',
    'SIRCA': 'Sirca',

    // ── Kamdhenu Paints ────────────────────────────────────────────
    'KAMDHENU PAINTS': 'Kamdhenu Paints',
    'KAMDHENU': 'Kamdhenu Paints',

    // ── Astral Paints (Gem Paints) ─────────────────────────────────
    'ASTRAL PAINTS': 'Astral Paints',
    'ASTRAL': 'Astral Paints',
    'GEM PAINTS': 'Gem Paints',

    // ── Snowcem Paints ─────────────────────────────────────────────
    'SNOWCEM PAINTS': 'Snowcem',
    'SNOWCEM': 'Snowcem',

    // ── Jotun Paints ───────────────────────────────────────────────
    'JOTUN PAINTS': 'Jotun',
    'JOTUN': 'Jotun',

    // ── Pidilite / ICA Pidilite ────────────────────────────────────
    'ICA PIDILITE': 'ICA Pidilite',
    'PIDILITE': 'Pidilite',
    'DR. FIXIT': 'Dr. Fixit',
    'DR FIXIT': 'Dr. Fixit',
    'ROFF': 'Roff',

    // ── MRF Corp (Vapocure / WoodCoat) ─────────────────────────────
    'MRF VAPOCURE': 'MRF Corp',
    'MRF PAINTS': 'MRF Corp',
    'MRF CORP': 'MRF Corp',
    'MRF': 'MRF Corp',

    // ── Surfa Coats Paints ─────────────────────────────────────────
    'SURFA COATS': 'Surfa Coats',
    'SURFACOATS': 'Surfa Coats',

    // ── Apollo Paints ──────────────────────────────────────────────
    'APOLLO PAINTS': 'Apollo Paints',

    // ── Sakarni Plasters & Paints ──────────────────────────────────
    'SAKARNI PAINTS': 'Sakarni',
    'SAKARNI': 'Sakarni',

    // ── National Paints ────────────────────────────────────────────
    'NATIONAL PAINTS': 'National Paints',

    // ── Garware Paints ─────────────────────────────────────────────
    'GARWARE PAINTS': 'Garware Paints',
    'GARWARE': 'Garware Paints',

    // ── Esdee Paints (Auto & Industrial) ───────────────────────────
    'ESDEE PAINTS': 'Esdee Paints',
    'ESDEE': 'Esdee Paints',

    // ── Grand Polycoats ────────────────────────────────────────────
    'GRAND POLYCOATS': 'Grand Polycoats',

    // ── Camlin (Kokuyo Camlin) ─────────────────────────────────────
    'KOKUYO CAMLIN': 'Camlin',
    'CAMLIN': 'Camlin',

    // ── Others / Specialty ─────────────────────────────────────────
    'MARVEL PAINTS': 'Marvel Paints',
    'VIPUL PAINTS': 'Vipul Paints',
    'RAL': 'RAL',
  };

  /// Mapping of major Indian paint sub-brands & product lines to their parent company.
  /// Resolves parent brand even when only sub-brand is prominent, and provides structured subBrand field.
  static final Map<String, _SubBrandMeta> _knownSubBrands = {
    // ── Asian Paints ────────────────────────────────────────────────
    'APCOLITE': _SubBrandMeta('Asian Paints', 'Apcolite'),
    'ROYALE': _SubBrandMeta('Asian Paints', 'Royale'),
    'APEX': _SubBrandMeta('Asian Paints', 'Apex'),
    'APEX ULTIMA': _SubBrandMeta('Asian Paints', 'Apex Ultima'),
    'ULTIMA': _SubBrandMeta('Asian Paints', 'Apex Ultima'),
    'TRACTOR': _SubBrandMeta('Asian Paints', 'Tractor'),
    'TRA EML': _SubBrandMeta('Asian Paints', 'Tractor'),
    'ACE': _SubBrandMeta('Asian Paints', 'Ace'),
    'SMARTCARE': _SubBrandMeta('Asian Paints', 'SmartCare'),
    'DAMPROOF': _SubBrandMeta('Asian Paints', 'SmartCare'),
    'WOODTECH': _SubBrandMeta('Asian Paints', 'WoodTech'),
    'TRUCARE': _SubBrandMeta('Asian Paints', 'TruCare'),
    'APCOFRESH': _SubBrandMeta('Asian Paints', 'ApcoFresh'),
    'APCOFRSH': _SubBrandMeta('Asian Paints', 'ApcoFresh'),
    'DECOPRIME': _SubBrandMeta('Asian Paints', 'DecoPrime'),
    'PGE': _SubBrandMeta('Asian Paints', 'PGE Enamel'),

    // ── Berger Paints ───────────────────────────────────────────────
    'WEATHERCOAT': _SubBrandMeta('Berger Paints', 'WeatherCoat'),
    'SILK GLAMOR': _SubBrandMeta('Berger Paints', 'Silk Glamor'),
    'SILK': _SubBrandMeta('Berger Paints', 'Silk'),
    'BISON': _SubBrandMeta('Berger Paints', 'Bison'),
    'LUXOL': _SubBrandMeta('Berger Paints', 'Luxol'),
    'WALMASTA': _SubBrandMeta('Berger Paints', 'Walmasta'),
    'BREATHE EASY': _SubBrandMeta('Berger Paints', 'Breathe Easy'),
    'WOODKEEPER': _SubBrandMeta('Berger Paints', 'WoodKeeper'),
    'HOMESHIELD': _SubBrandMeta('Berger Paints', 'HomeShield'),
    'ILLUSION': _SubBrandMeta('Berger Paints', 'Illusion'),
    'RANGOLI': _SubBrandMeta('Berger Paints', 'Rangoli'),

    // ── Kansai Nerolac ──────────────────────────────────────────────
    'IMPRESSIONS': _SubBrandMeta('Kansai Nerolac', 'Impressions'),
    'EXCEL': _SubBrandMeta('Kansai Nerolac', 'Excel'),
    'BEAUTY': _SubBrandMeta('Kansai Nerolac', 'Beauty'),
    'SURAKSHA': _SubBrandMeta('Kansai Nerolac', 'Suraksha'),
    'SOLDIER': _SubBrandMeta('Kansai Nerolac', 'Soldier'),
    'PERMASHIELD': _SubBrandMeta('Kansai Nerolac', 'PermaShield'),

    // ── AkzoNobel / Dulux ───────────────────────────────────────────
    'VELVET TOUCH': _SubBrandMeta('Dulux', 'Velvet Touch'),
    'WEATHERSHIELD': _SubBrandMeta('Dulux', 'Weathershield'),
    'PROMISE': _SubBrandMeta('Dulux', 'Promise'),
    'SIMPLY REFRESH': _SubBrandMeta('Dulux', 'Simply Refresh'),
    'SUPERCLEAN': _SubBrandMeta('Dulux', 'SuperClean'),
    'AQUATECH': _SubBrandMeta('Dulux', 'Aquatech'),
    'DUWEL': _SubBrandMeta('Dulux', 'Duwel'),

    // ── Birla Opus (Aditya Birla Group) ─────────────────────────────
    'CALISTA': _SubBrandMeta('Birla Opus', 'Calista'),
    'STYLE': _SubBrandMeta('Birla Opus', 'Style'),
    'PRIME': _SubBrandMeta('Birla Opus', 'Prime'),
    'ALLDRY': _SubBrandMeta('Birla Opus', 'AllDry'),
    'ALLWOOD': _SubBrandMeta('Birla Opus', 'AllWood'),
    'ONE': _SubBrandMeta('Birla Opus', 'One'),

    // ── JSW Paints ──────────────────────────────────────────────────
    'HALO': _SubBrandMeta('JSW Paints', 'Halo'),
    'AURUS': _SubBrandMeta('JSW Paints', 'Aurus'),
    'PIXA': _SubBrandMeta('JSW Paints', 'Pixa'),

    // ── Nippon Paint ────────────────────────────────────────────────
    'WEATHERBOND': _SubBrandMeta('Nippon Paint', 'Weatherbond'),
    'SPOTLESS': _SubBrandMeta('Nippon Paint', 'Spotless'),
    'SATIN GLO': _SubBrandMeta('Nippon Paint', 'Satin Glo'),
    'BREEZE': _SubBrandMeta('Nippon Paint', 'Breeze'),
    'SUMO': _SubBrandMeta('Nippon Paint', 'Sumo'),
    'BODELAC': _SubBrandMeta('Nippon Paint', 'Bodelac'),
    'AIRCARE': _SubBrandMeta('Nippon Paint', 'AirCare'),
    'MATEX': _SubBrandMeta('Nippon Paint', 'Matex'),

    // ── Indigo Paints ───────────────────────────────────────────────
    'BRIGHT CEILING': _SubBrandMeta('Indigo Paints', 'Bright Ceiling Coat'),
    'DIRTPROOF': _SubBrandMeta('Indigo Paints', 'Dirtproof'),
    'FLOOR COAT': _SubBrandMeta('Indigo Paints', 'Floor Coat'),
    'TILE COAT': _SubBrandMeta('Indigo Paints', 'Tile Coat'),

    // ── British Paints ──────────────────────────────────────────────
    'SHINGLE': _SubBrandMeta('British Paints', 'Shingle'),
    'GLAMOUR': _SubBrandMeta('British Paints', 'Glamour'),
    'ACRI-SILK': _SubBrandMeta('British Paints', 'Acri-Silk'),
    'STAINGARD': _SubBrandMeta('British Paints', 'Staingard'),
    'EXPA COOL': _SubBrandMeta('British Paints', 'Expa Cool'),

    // ── Shalimar Paints ─────────────────────────────────────────────
    'SUPERLAC': _SubBrandMeta('Shalimar Paints', 'Superlac'),
    'WEATHER PRO': _SubBrandMeta('Shalimar Paints', 'Weather Pro'),
    'SIGNATURE': _SubBrandMeta('Shalimar Paints', 'Signature'),
    'SHAKTIMAN': _SubBrandMeta('Shalimar Paints', 'Shaktiman'),

    // ── MRF Corp ────────────────────────────────────────────────────
    'VAPOCURE': _SubBrandMeta('MRF Corp', 'Vapocure'),
    'WOODCOAT': _SubBrandMeta('MRF Corp', 'WoodCoat'),
    'METALCOAT': _SubBrandMeta('MRF Corp', 'MetalCoat'),

    // ── Pidilite ────────────────────────────────────────────────────
    'DR. FIXIT': _SubBrandMeta('Pidilite', 'Dr. Fixit'),
    'DR FIXIT': _SubBrandMeta('Pidilite', 'Dr. Fixit'),
    'ROFF': _SubBrandMeta('Pidilite', 'Roff'),
  };

  // Specific paint product prefixes and types
  static final List<String> _paintPrefixes = [
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

  // Tokens that are brand names and should NOT be returned as paint names
  // NOTE: APCOLITE, APCOFRESH, APEX, ROYALE are product sub-brands of Asian Paints — they stay in paint name.
  static final Set<String> _brandTokensToSkip = {
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

  /// Extract structured Key-Value data from raw OCR lines
  static PaintLabelData extract(List<String> rawLines, [String? fullText]) {
    String? packQuantity;
    String? mfd;
    String? batchNo;

    // Phase 1: Extract Pack Quantity, Mfd Date, Batch No.
    for (int i = 0; i < rawLines.length; i++) {
      final line = rawLines[i].trim();
      if (line.isEmpty) continue;

      // 1. Pack Quantity
      if (packQuantity == null) {
        final packMatch = _packQtyRegex.firstMatch(line);
        if (packMatch != null) {
          var qty = packMatch.group(0)?.trim();
          if (qty != null) {
            qty = qty.replaceAll(RegExp(r'\bHET\b', caseSensitive: false), 'NET');
            // If line is e.g. "1L" and next line is "NET" or "HET"
            if (!qty.toUpperCase().contains('NET') && i + 1 < rawLines.length) {
              final next = rawLines[i + 1].trim().toUpperCase();
              if (next == 'NET' || next == 'HET') {
                qty = '$qty NET';
              }
            }
            packQuantity = qty;
          }
        }
      }

      // 2. Mfd Date
      if (mfd == null) {
        final mfdMatch = _mfdRegex.firstMatch(line);
        if (mfdMatch != null) {
          var matched = mfdMatch.group(1)?.trim();
          if (matched != null && RegExp(r'^\d{6}$').hasMatch(matched)) {
            matched = '${matched.substring(0, 2)}/${matched.substring(2)}';
          }
          mfd = matched;
        } else {
          // Check for standalone date e.g. "08/2026 BEST BEFORE"
          final dateMatch = RegExp(r'\b(0[1-9]|1[0-2])/(20\d{2})\b').firstMatch(line);
          if (dateMatch != null) {
            mfd = dateMatch.group(0);
          }
        }
      }

      // 3. Batch Number
      if (batchNo == null) {
        final batchMatch = _batchRegex.firstMatch(line);
        if (batchMatch != null) {
          batchNo = batchMatch.group(1)?.trim();
        }
      }
    }

    // Phase 2: Dedicated, Robust Extraction of Unit Sale Price and MRP
    String? unitSalePrice = _extractUnitSalePrice(rawLines, packQuantity: packQuantity);
    String? mrp = _extractMrp(
      rawLines,
      packQuantity: packQuantity,
      unitSalePrice: unitSalePrice,
      fullText: fullText,
    );

    // Cross-validation sanity check:
    // MRP is the total pack price, whereas Unit Sale Price is the per-unit rate.
    if (mrp != null && unitSalePrice != null) {
      final mrpNumeric = _parseAmount(mrp);
      final uspNumeric = _parseAmount(unitSalePrice);

      // If both are valid numbers and pack is multi-pack/litre, MRP must be greater than USP
      if (mrpNumeric != null && uspNumeric != null && mrpNumeric < uspNumeric) {
        // Swap if somehow transposed
        mrp = '₹ ${_formatAmount(uspNumeric)}';
        final unit = unitSalePrice.contains('ml') ? 'ml' : 'litre';
        unitSalePrice = '₹ ${_formatAmount(mrpNumeric)} / $unit';
      }
    } else if (mrp == null && unitSalePrice != null) {
      // Fallback derivation if MRP text block was unreadable
      final uspNumeric = _parseAmount(unitSalePrice);
      final packVolume = _parsePackVolumeInLitres(packQuantity);
      if (uspNumeric != null && packVolume != null && packVolume > 0) {
        final calcMrp = uspNumeric * packVolume;
        mrp = '₹ ${_formatAmount(calcMrp)}';
      }
    } else if (unitSalePrice == null && mrp != null) {
      // Fallback derivation if USP was unreadable
      final mrpNumeric = _parseAmount(mrp);
      final packVolume = _parsePackVolumeInLitres(packQuantity);
      if (mrpNumeric != null && packVolume != null && packVolume > 0) {
        final calcUsp = mrpNumeric / packVolume;
        final unit = (packQuantity != null && packQuantity.toLowerCase().contains('ml') && packVolume < 1.0) ? 'ml' : 'litre';
        unitSalePrice = '₹ ${_formatAmount(calcUsp)} / $unit';
      }
    }

    // Phase 3: Brand & Sub-Brand Extraction
    final (brandName, subBrand) = _extractBrandAndSubBrand(rawLines);

    // Phase 4: Paint Name Extraction (Must NOT be the brand name!)
    final paintName = _extractPaintName(rawLines, brandName: brandName, subBrand: subBrand);

    // Phase 5: Base and Hardener Extraction (for 2-pack, PU, and base paints)
    final base = _extractBase(rawLines, paintName: paintName);
    final hardener = _extractHardener(rawLines);

    // Fallback batch number if not found with "B.No." anchor
    batchNo ??= _extractFallbackBatch(rawLines, mfd);

    return PaintLabelData(
      brandName: brandName,
      subBrand: subBrand,
      paintName: paintName,
      packQuantity: packQuantity,
      mrp: mrp,
      unitSalePrice: unitSalePrice,
      mfd: mfd,
      batchNo: batchNo,
      base: base,
      hardener: hardener,
      rawText: fullText ?? rawLines.join('\n'),
      rawLines: rawLines,
    );
  }

  /// Cleans OCR text for brand matching: strips accents/diacritics and non-alphanumeric noise
  static String _cleanOcrToken(String text) {
    return text
        .replaceAll(RegExp(r'[ôöòóõ]', caseSensitive: false), 'o')
        .replaceAll(RegExp(r'[éèêë]', caseSensitive: false), 'e')
        .replaceAll(RegExp(r'[àáâãä]', caseSensitive: false), 'a')
        .replaceAll(RegExp(r'[îïíì]', caseSensitive: false), 'i')
        .replaceAll(RegExp(r'[ûüùú]', caseSensitive: false), 'u')
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
        .trim();
  }

  /// Calculates Levenshtein edit distance between two strings
  static int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        final cost = (s.codeUnitAt(i) == t.codeUnitAt(j)) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[t.length];
  }

  /// Extracts the paint brand name from OCR lines.
  /// Checks each line for known brand tokens and returns the canonical display name.
  static String? _extractBrandName(List<String> rawLines) {
    // Pass 1: Multi-word brands exact check (e.g. "ASIAN PAINTS", "BIRLA OPUS", "KANSAI NEROLAC")
    for (final line in rawLines) {
      final upper = line.trim().toUpperCase();
      for (final entry in _knownBrands.entries) {
        if (entry.key.contains(' ')) {
          if (upper.contains(entry.key)) {
            return entry.value;
          }
        }
      }
    }

    // Pass 2: Single-word brand tokens (exact word-boundary match on raw text)
    for (final line in rawLines) {
      final upper = line.trim().toUpperCase();
      for (final entry in _knownBrands.entries) {
        if (entry.key.contains(' ')) continue;
        if (RegExp('\\b${RegExp.escape(entry.key)}\\b').hasMatch(upper)) {
          return entry.value;
        }
      }
    }

    // Pass 3: Cleaned text exact match (strips diacritics and surrounding punctuation e.g. "ôpcolie," -> "OPCOLIE")
    for (final line in rawLines) {
      final cleaned = _cleanOcrToken(line).toUpperCase();
      if (cleaned.isEmpty) continue;
      for (final entry in _knownBrands.entries) {
        if (entry.key.contains(' ')) {
          if (cleaned.contains(entry.key)) return entry.value;
        } else {
          if (RegExp('\\b${RegExp.escape(entry.key)}\\b').hasMatch(cleaned)) {
            return entry.value;
          }
        }
      }
    }

    // Pass 4: OCR distortion regex for stylized sub-brand logos belonging to Asian Paints (e.g. Apcolite: "ôpcolie", "oPcplile", "pcblite", "PColitep")
    final apcoliteOcrRegex = RegExp(r'^[o0a@]?[pP]+c[o0b@]?[pP]?l[i1l][t+l]?[e3]?[a-z]?$', caseSensitive: false);
    for (final line in rawLines) {
      final cleaned = _cleanOcrToken(line);
      for (final word in cleaned.split(RegExp(r'\s+'))) {
        if (word.length >= 5 && apcoliteOcrRegex.hasMatch(word)) {
          return 'Asian Paints';
        }
      }
    }

    // Pass 5: Fuzzy Levenshtein match on tokens (distance <= 2 for words >= 6 chars, <= 3 for words >= 8 chars)
    for (final line in rawLines) {
      final cleaned = _cleanOcrToken(line).toUpperCase();
      if (cleaned.isEmpty) continue;
      for (final word in cleaned.split(RegExp(r'\s+'))) {
        if (word.length < 5) continue;
        for (final entry in _knownBrands.entries) {
          if (entry.key.contains(' ')) continue;
          final brandKey = entry.key;
          if (brandKey.length < 6) continue;
          final maxDist = brandKey.length >= 8 ? 3 : 2;
          final dist = _levenshtein(word, brandKey);
          if (dist <= maxDist) {
            return entry.value;
          }
        }
      }
    }

    return null;
  }

  /// Extracts both Parent Brand (manufacturer) and Sub-Brand (product range/line)
  static (String? brandName, String? subBrand) _extractBrandAndSubBrand(List<String> rawLines) {
    String? brand = _extractBrandName(rawLines);
    String? subBrand;

    // 1. Check for multi-word sub-brands first (e.g. "APEX ULTIMA", "VELVET TOUCH", "SILK GLAMOR")
    for (final line in rawLines) {
      final upper = line.trim().toUpperCase();
      for (final entry in _knownSubBrands.entries) {
        if (entry.key.contains(' ')) {
          if (upper.contains(entry.key)) {
            subBrand ??= entry.value.subBrand;
            brand ??= entry.value.parentBrand;
            break;
          }
        }
      }
      if (subBrand != null) break;
    }

    // 2. Check for single-word sub-brands (e.g. "ROYALE", "WEATHERCOAT", "IMPRESSIONS", "CALISTA", "HALO", "APEX", "BISON")
    if (subBrand == null) {
      for (final line in rawLines) {
        final upper = line.trim().toUpperCase();
        for (final entry in _knownSubBrands.entries) {
          if (entry.key.contains(' ')) continue;
          if (RegExp('\\b${RegExp.escape(entry.key)}\\b').hasMatch(upper)) {
            subBrand = entry.value.subBrand;
            brand ??= entry.value.parentBrand;
            break;
          }
        }
        if (subBrand != null) break;
      }
    }

    // 3. Check cleaned / stylized OCR tokens (e.g. Apcolite: ôpcolie, oPcplile, pcblite)
    if (subBrand == null) {
      final apcoliteOcrRegex = RegExp(r'^[o0a@]?[pP]+c[o0b@]?[pP]?l[i1l][t+l]?[e3]?[a-z]?$', caseSensitive: false);
      for (final line in rawLines) {
        final cleaned = _cleanOcrToken(line);
        for (final word in cleaned.split(RegExp(r'\s+'))) {
          if (word.length >= 5 && apcoliteOcrRegex.hasMatch(word)) {
            subBrand = 'Apcolite';
            brand ??= 'Asian Paints';
            break;
          }
        }
        if (subBrand != null) break;
      }
    }

    return (brand, subBrand);
  }

  /// Robust MRP Extraction handling inline, stacked lines, taxes anchors, multi-block OCR, and mathematical verification
  static String? _extractMrp(
    List<String> rawLines, {
    String? packQuantity,
    String? unitSalePrice,
    String? fullText,
  }) {
    final double? uspNumeric = unitSalePrice != null ? _parseAmount(unitSalePrice) : null;
    final double? packVolume = _parsePackVolumeInLitres(packQuantity);

    // Pass 1: Direct match on lines mentioning MRP / M.R.P. / HAP / MAP / MAX RETAIL PRICE
    for (int i = 0; i < rawLines.length; i++) {
      final line = rawLines[i].trim();
      final upper = line.toUpperCase();

      // Skip lines that are specifically Unit Sale Price lines
      if (upper.contains('UNIT SALE PRICE') ||
          upper.contains('UNIT SALE') ||
          upper.contains('UNIT PRICE') ||
          upper.contains('USP') ||
          upper.contains('PER LITRE') ||
          upper.contains('PERLITRE') ||
          upper.contains('PER ML') ||
          upper.contains('PERML')) {
        continue;
      }

      // Check if line mentions MRP or Retail Price or common OCR variants (HAP, MAP, NRP, MBP)
      if (RegExp(r'(?:M\.?\s*R\.?\s*P\.?|HAP|MAP|NRP|MBP|MRF|MAX(?:IMUM)?\s*RETAIL\s*PRICE)', caseSensitive: false).hasMatch(line)) {
        // 1) Amount directly on the same line
        final sameLineMatch = RegExp(
          r'(?:M\.?\s*R\.?\s*P\.?|HAP|MAP|NRP|MBP|MRF|MAX(?:IMUM)?\s*RETAIL\s*PRICE)[^\d\n]*?(?:₹|Rs\.?|INR|[F*?z])?\s*([\d,]+(?:\.\d{1,2})?)',
          caseSensitive: false,
        ).firstMatch(line);

        if (sameLineMatch != null && sameLineMatch.group(1) != null) {
          final val = sameLineMatch.group(1)!.replaceAll(',', '');
          if (_isValidPrice(val)) {
            final numVal = double.tryParse(val);
            if (uspNumeric == null || numVal == null || (numVal - uspNumeric).abs() > 0.05 || (packVolume != null && packVolume <= 1.0)) {
              return '₹ ${_formatAmount(numVal ?? double.parse(val))}';
            }
          }
        }

        // 2) Amount on subsequent lines (up to 4 lines ahead, e.g. stacked or multi-line labels)
        for (int j = 1; j <= 4 && i + j < rawLines.length; j++) {
          final nextLine = rawLines[i + j].trim();
          final nextUpper = nextLine.toUpperCase();

          // Skip lines that are specifically Unit Sale Price
          if (nextUpper.contains('PER LITRE') ||
              nextUpper.contains('PERLITRE') ||
              nextUpper.contains('PER ML') ||
              nextUpper.contains('PERML') ||
              nextUpper.contains('0001 ')) {
            continue;
          }

          // Look for amount (ignoring leading currency symbol or "incl. of all taxes")
          final nextMatch = RegExp(
            r'^(?:(?:₹|Rs\.?|INR|[F*?z])\s*)?([\d,]+(?:\.\d{1,2})?)(?:\s*(?:incl|all\s*taxes|[A-Z0-9]+))?',
            caseSensitive: false,
          ).firstMatch(nextLine);

          if (nextMatch != null && nextMatch.group(1) != null) {
            final val = nextMatch.group(1)!.replaceAll(',', '');
            if (_isValidPrice(val)) {
              final numVal = double.tryParse(val);
              if (uspNumeric == null || numVal == null || (numVal - uspNumeric).abs() > 0.05 || (packVolume != null && packVolume <= 1.0)) {
                return '₹ ${_formatAmount(numVal ?? double.parse(val))}';
              }
            }
          }
        }
      }
    }

    // Pass 2: "incl. of all taxes" anchor (and OCR variants: INL. CF AL TRES, nc. of all taGpa)
    for (int i = 0; i < rawLines.length; i++) {
      final line = rawLines[i].trim();
      final upper = line.toUpperCase();

      final isTaxesLine = RegExp(
        r'(?:INCL|INL|INC|NC)\.?\s*(?:OF|CF)?\s*(?:ALL|AL)?\s*(?:TAX|TAG|TRE)',
        caseSensitive: false,
      ).hasMatch(line) || (upper.contains('TAX') || upper.contains('TAG') || upper.contains('TRE'));

      if (isTaxesLine) {
        if (upper.contains('PER LITRE') || upper.contains('PERML') || upper.contains('UNIT SALE')) {
          continue;
        }

        // 1) Amount on this same line
        final sameLineMatch = RegExp(
          r'(?:(?:₹|Rs\.?|INR|[F*?z])\s*)?([\d,]+(?:\.\d{1,2})?)\s*(?:incl)',
          caseSensitive: false,
        ).firstMatch(line);

        if (sameLineMatch != null && sameLineMatch.group(1) != null) {
          final val = sameLineMatch.group(1)!.replaceAll(',', '');
          if (_isValidPrice(val)) {
            return '₹ ${_formatAmount(double.parse(val))}';
          }
        }

        // 2) Amount on PRECEDING lines (up to 3 lines back, e.g. "Best485.00" -> "before 60 months" -> "nc. of all taGpa")
        for (int k = 1; k <= 3 && i - k >= 0; k++) {
          final prevLine = rawLines[i - k].trim();
          final prevUpper = prevLine.toUpperCase();
          if (prevUpper.contains('UNIT SALE') || prevUpper.contains('PER LITRE')) continue;

          final prevMatch = RegExp(
            r'([\d,]+(?:\.\d{2}))',
            caseSensitive: false,
          ).firstMatch(prevLine);

          if (prevMatch != null && prevMatch.group(1) != null) {
            final val = prevMatch.group(1)!.replaceAll(',', '');
            if (_isValidPrice(val)) {
              return '₹ ${_formatAmount(double.parse(val))}';
            }
          }
        }

        // 3) Amount on NEXT line (i+1)
        if (i + 1 < rawLines.length) {
          final nextLine = rawLines[i + 1].trim();
          final nextUpper = nextLine.toUpperCase();
          if (!nextUpper.contains('UNIT SALE') && !nextUpper.contains('PER LITRE')) {
            final nextMatch = RegExp(
              r'^(?:(?:₹|Rs\.?|INR|[F*?z])\s*)?([\d,]+(?:\.\d{1,2})?)',
              caseSensitive: false,
            ).firstMatch(nextLine);

            if (nextMatch != null && nextMatch.group(1) != null) {
              final val = nextMatch.group(1)!.replaceAll(',', '');
              if (_isValidPrice(val)) {
                return '₹ ${_formatAmount(double.parse(val))}';
              }
            }
          }
        }
      }
    }

    // Pass 3: Mathematical match using USP and Pack Quantity in rawLines / fullText
    // e.g. 20L * ₹ 425.50 = ₹ 8510.00; 10L * ₹ 223.00 = ₹ 2230.00
    if (uspNumeric != null && packVolume != null && packVolume > 1.0) {
      final calculatedMrp = uspNumeric * packVolume;
      final expectedStr = calculatedMrp.toStringAsFixed(2);
      final expectedRound = calculatedMrp.toStringAsFixed(0);

      // Check if expected price appears in any line
      final allText = fullText ?? rawLines.join('\n');
      if (allText.contains(expectedStr) || allText.contains(expectedRound)) {
        return '₹ $expectedStr';
      }
    }

    // Pass 4: Multi-block / Disconnected MRP search
    // When OCR places pre-printed text in one block and inkjet price in another block,
    // search for any standalone currency line that is NOT the USP
    for (final line in rawLines) {
      final trimmed = line.trim();
      final upper = trimmed.toUpperCase();

      // Skip lines with other information
      if (upper.contains('PER LITRE') ||
          upper.contains('PERLITRE') ||
          upper.contains('PER ML') ||
          upper.contains('PERML') ||
          upper.contains('UNIT SALE') ||
          upper.contains('MFD') ||
          upper.contains('EXP') ||
          upper.contains('NET') ||
          upper.contains('BEST BEFORE') ||
          upper.contains('1800') ||
          upper.contains('/') ||
          upper.contains('-')) {
        continue;
      }

      // Check for standalone price line with Rupee symbol, e.g. "₹ 8510.00", "₹ 2230.00", "₹8510.00 AB2"
      final priceWithSymbolMatch = RegExp(
        r'(?:₹|Rs\.?|INR)\s*([\d,]+(?:\.\d{2}))',
        caseSensitive: false,
      ).firstMatch(trimmed);

      if (priceWithSymbolMatch != null && priceWithSymbolMatch.group(1) != null) {
        final val = priceWithSymbolMatch.group(1)!.replaceAll(',', '');
        final num = double.tryParse(val);
        if (num != null && _isValidPrice(val)) {
          if (uspNumeric == null || (num - uspNumeric).abs() > 0.05) {
            return '₹ ${_formatAmount(num)}';
          }
        }
      }

      // Check for standalone decimal amount, e.g. "8510.00" or "2230.00"
      final standaloneDecimalMatch = RegExp(
        r'^\s*([\d,]+(?:\.\d{2}))\s*(?:[A-Za-z0-9]+)?$',
      ).firstMatch(trimmed);

      if (standaloneDecimalMatch != null && standaloneDecimalMatch.group(1) != null) {
        final val = standaloneDecimalMatch.group(1)!.replaceAll(',', '');
        final num = double.tryParse(val);
        if (num != null && _isValidPrice(val)) {
          if (uspNumeric == null || (num - uspNumeric).abs() > 0.05) {
            if (packVolume != null && packVolume > 1.0 && uspNumeric != null && num > uspNumeric) {
              return '₹ ${_formatAmount(num)}';
            } else if (packVolume == null || packVolume <= 1.0) {
              return '₹ ${_formatAmount(num)}';
            }
          }
        }
      }
    }

    // Pass 4b: Embedded decimal amount attached to words (e.g. "Best485.00" or "Rs485.00")
    for (final line in rawLines) {
      final upper = line.trim().toUpperCase();
      if (upper.contains('PER LITRE') ||
          upper.contains('PERLITRE') ||
          upper.contains('PER ML') ||
          upper.contains('PERML') ||
          upper.contains('UNIT SALE') ||
          upper.contains('MFD') ||
          upper.contains('EXP') ||
          upper.contains('1800') ||
          upper.contains('/') ||
          upper.contains('-')) {
        continue;
      }

      final embeddedDecimalMatch = RegExp(r'([\d,]+(?:\.\d{2}))').firstMatch(line);
      if (embeddedDecimalMatch != null && embeddedDecimalMatch.group(1) != null) {
        final val = embeddedDecimalMatch.group(1)!.replaceAll(',', '');
        final num = double.tryParse(val);
        if (num != null && _isValidPrice(val)) {
          if (uspNumeric == null || (num - uspNumeric).abs() > 0.05) {
            return '₹ ${_formatAmount(num)}';
          }
        }
      }
    }

    // Pass 5: Mathematical Fallback if calculation is confident
    if (uspNumeric != null && packVolume != null && packVolume > 0.0) {
      final calculatedMrp = uspNumeric * packVolume;
      if (calculatedMrp >= 50.0) {
        return '₹ ${_formatAmount(calculatedMrp)}';
      }
    }

    return null;
  }

  /// Extracts total numeric volume in litres from pack quantity string
  /// Handles "20L NET" (20L), "10L NET" (10L), "4Nos. x 4L NET" (16L), "8Nos. x 500ml NET" (4L), "500ml NET" (0.5L)
  static double? _parsePackVolumeInLitres(String? packQty) {
    if (packQty == null || packQty.trim().isEmpty) return null;
    final clean = packQty.trim().toLowerCase();

    // 1. Multipack: e.g. "4Nos. x 4L NET" or "8Nos. x 500ml NET"
    final multiMatch = RegExp(r'(\d+)\s*(?:nos?\.?)?\s*[xX*]\s*([\d.]+)\s*(ml|l|litre|liter|ltr)', caseSensitive: false).firstMatch(clean);
    if (multiMatch != null) {
      final count = double.tryParse(multiMatch.group(1)!);
      final size = double.tryParse(multiMatch.group(2)!);
      final unit = multiMatch.group(3)!.toLowerCase();
      if (count != null && size != null) {
        if (unit.contains('ml')) {
          return (count * size) / 1000.0;
        }
        return count * size;
      }
    }

    // 2. Single container volume: e.g. "20L NET", "10L NET", "4L NET", "500ml NET"
    final singleMatch = RegExp(r'([\d.]+)\s*(ml|l|litre|liter|ltr)', caseSensitive: false).firstMatch(clean);
    if (singleMatch != null) {
      final size = double.tryParse(singleMatch.group(1)!);
      final unit = singleMatch.group(2)!.toLowerCase();
      if (size != null) {
        if (unit.contains('ml')) {
          return size / 1000.0;
        }
        return size;
      }
    }
    return null;
  }

  /// Robust Unit Sale Price (USP) Extraction handling inline, stacked lines, and standalone rates
  static String? _extractUnitSalePrice(List<String> rawLines, {String? packQuantity}) {
    // Pass 1: Line contains UNIT SALE PRICE / USP / UNIT PRICE
    for (int i = 0; i < rawLines.length; i++) {
      final line = rawLines[i].trim();
      final upper = line.toUpperCase();

      if (upper.contains('UNIT SALE PRICE') ||
          upper.contains('UNIT SALE') ||
          upper.contains('UNIT PRICE') ||
          upper.contains('USP')) {
        // 1) Same line match: e.g. "UNIT SALE PRICE ₹ 397.50 PER litre" or "UNIT SALE PRICE ₹0.43 PERml"
        final sameLineMatch = RegExp(
          r'(?:UNIT\s*SALE\s*PRICE|UNIT\s*PRICE|USP)[\s:.-]*[^\d\n]*?(?:₹|Rs\.?|INR|[F*?])?\s*([\d,]+(?:\.\d{1,2})?)\s*(?:PER\s*|/\s*)?(litre|liter|ltr|l|ml)?',
          caseSensitive: false,
        ).firstMatch(line);

        if (sameLineMatch != null && sameLineMatch.group(1) != null && sameLineMatch.group(1)!.isNotEmpty) {
          final val = sameLineMatch.group(1)!.replaceAll(',', '');
          if (_isValidUsp(val)) {
            final unit = _normalizeUnit(sameLineMatch.group(2), packQuantity);
            return '₹ $val / $unit';
          }
        }

        // 2) Look ahead up to 2 lines for price and unit:
        // Handles: Line i: "UNIT SALE PRICE"
        // Line i+1: "₹ 425.50 PER LITRE" or "₹ 223.00 PERLITRE" or "₹ 425.50"
        for (int j = 1; j <= 2 && i + j < rawLines.length; j++) {
          final nextLine = rawLines[i + j].trim();
          final nextUpper = nextLine.toUpperCase();

          if (nextUpper.contains('MFD') ||
              nextUpper.contains('BEST BEFORE') ||
              nextUpper.contains('LEAD CONTENT')) {
            break;
          }

          final priceMatch = RegExp(
            r'(?:₹|Rs\.?|INR|[F*?])?\s*([\d,]+(?:\.\d{1,2})?)\s*(?:PER\s*|/\s*)?(litre|liter|ltr|l|ml)?',
            caseSensitive: false,
          ).firstMatch(nextLine);

          if (priceMatch != null && priceMatch.group(1) != null && priceMatch.group(1)!.isNotEmpty) {
            final val = priceMatch.group(1)!.replaceAll(',', '');
            if (_isValidUsp(val)) {
              String? unitGroup = priceMatch.group(2);

              // Check if the next line after price has the unit (e.g. Line i+j: "425.50", Line i+j+1: "PER LITRE")
              if (unitGroup == null && i + j + 1 < rawLines.length) {
                final unitLine = rawLines[i + j + 1].trim();
                final unitMatch = RegExp(r'(?:PER\s*|/\s*)?(litre|liter|ltr|l|ml)\b', caseSensitive: false).firstMatch(unitLine);
                if (unitMatch != null) {
                  unitGroup = unitMatch.group(1);
                }
              }

              final unit = _normalizeUnit(unitGroup, packQuantity);
              return '₹ $val / $unit';
            }
          }
        }
      }
    }

    // Pass 2: Standalone rate with unit: e.g. "₹ 425.50 PER LITRE", "₹ 223.00 PERLITRE", "₹0.43 PERml", "₹ 397.50 / litre"
    for (final line in rawLines) {
      final standaloneMatch = RegExp(
        r'(?:₹|Rs\.?|INR|[F*?])?\s*([\d,]+(?:\.\d{1,2})?)\s*(?:PER\s*|/\s*)(litre|liter|ltr|l|ml)\b',
        caseSensitive: false,
      ).firstMatch(line);

      if (standaloneMatch != null && standaloneMatch.group(1) != null) {
        final val = standaloneMatch.group(1)!.replaceAll(',', '');
        if (_isValidUsp(val)) {
          final unit = _normalizeUnit(standaloneMatch.group(2), packQuantity);
          return '₹ $val / $unit';
        }
      }
    }

    return null;
  }

  /// Normalizes unit to standard "litre" or "ml"
  static String _normalizeUnit(String? unitGroup, String? packQuantity) {
    if (unitGroup != null && unitGroup.isNotEmpty) {
      final u = unitGroup.toLowerCase();
      if (u.contains('ml')) return 'ml';
      return 'litre';
    }
    if (packQuantity != null && packQuantity.toLowerCase().contains('ml')) {
      return 'ml';
    }
    return 'litre';
  }

  /// Validates price string to ensure it's not a year, phone number, or date
  static bool _isValidPrice(String val) {
    final num = double.tryParse(val);
    if (num == null) return false;
    // Exclude common years (2020 - 2030) if formatted with no decimal
    if (num >= 2020 && num <= 2035 && !val.contains('.')) return false;
    // Price must be reasonable (e.g., above 10 rupees)
    return num >= 10.0 && num < 1000000.0;
  }

  /// Validates unit sale price string
  static bool _isValidUsp(String val) {
    final num = double.tryParse(val);
    if (num == null) return false;
    // Unit price can be small decimal like 0.43 for ml or up to several thousands for litres
    return num > 0.01 && num < 50000.0;
  }

  /// Parses numeric amount from currency string
  static double? _parseAmount(String text) {
    final match = RegExp(r'([\d,]+(?:\.\d{1,2})?)').firstMatch(text);
    if (match != null && match.group(1) != null) {
      return double.tryParse(match.group(1)!.replaceAll(',', ''));
    }
    return null;
  }

  /// Formats amount nicely with 2 decimals
  static String _formatAmount(double amount) {
    return amount.toStringAsFixed(2);
  }

  /// Checks if a string contains corporate/brand boilerplate
  static bool _isBrandOrBoilerplate(String text) {
    final upper = text.toUpperCase();
    return _brandAndBoilerplate.any((b) => upper.contains(b));
  }

  /// Cleans and formats extracted paint name
  static String _cleanPaintName(String text) {
    return text
        .replaceAll(RegExp(r'^(?:Paints|0001\s*\d+\s*\d+)\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'[/,;]+$'), '')
        .replaceAll(RegExp(r'^[/,;]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Extracts specifically the Paint/Shade name, strictly ignoring brand names like "Asian Paints Ltd"
  static String? _extractPaintName(List<String> rawLines, {String? brandName, String? subBrand}) {
    // Preprocess rawLines to fix common OCR token splits/glues:
    // e.g. "PREMI" + "JM ENAMEL" -> "PREMIUM ENAMEL", "ENA MEL" -> "ENAMEL"
    final effectiveLines = <String>[];
    for (int idx = 0; idx < rawLines.length; idx++) {
      var l = rawLines[idx].trim();
      l = l.replaceAll(RegExp(r'\bENA\s+MEL\b', caseSensitive: false), 'ENAMEL');
      if (RegExp(r'^PREMI$', caseSensitive: false).hasMatch(l) && idx + 1 < rawLines.length) {
        final nextL = rawLines[idx + 1].trim();
        if (RegExp(r'^(?:[JJU]M\s+)?ENAMEL\b', caseSensitive: false).hasMatch(nextL)) {
          l = 'PREMIUM ENAMEL';
          idx++; // skip next line
        }
      }
      effectiveLines.add(l);
    }

    // Build a set of brand tokens to strip from candidates
    final brandTokensUpper = <String>{};
    if (brandName != null) {
      // Add the canonical brand name tokens
      brandTokensUpper.add(brandName.toUpperCase());
      // Also add all matching keys from _knownBrands that map to this brand (excluding sub-brands like APCOLITE)
      for (final entry in _knownBrands.entries) {
        if (entry.value == brandName && entry.key != 'APCOLITE') {
          brandTokensUpper.add(entry.key);
        }
      }
    }
    brandTokensUpper.addAll(_brandTokensToSkip);

    /// Checks if a line is a brand anchor line (exact or OCR-distorted like "ôpcolie,", "oPcplile", "pcblite")
    bool isBrandAnchorLine(String line) {
      final upper = line.trim().toUpperCase();
      if (brandTokensUpper.contains(upper)) return true;
      final cleaned = _cleanOcrToken(upper);
      if (cleaned.length >= 4) {
        if (brandName != null && cleaned.contains(brandName.toUpperCase())) return true;
        if (RegExp(r'^[o0a@]?[pP]+c[o0b@]?[pP]?l[i1l][t+l]?[e3]?[a-z]?$', caseSensitive: false).hasMatch(cleaned)) {
          return true;
        }
      }
      return false;
    }

    /// Strips brand prefix from a candidate string
    String stripBrand(String candidate) {
      var result = candidate.trim();
      for (final token in brandTokensUpper) {
        // Remove token from the start of result (case-insensitive)
        result = result.replaceFirst(
          RegExp('^${RegExp.escape(token)}\\s*', caseSensitive: false),
          '',
        );
      }
      return result.trim();
    }

    /// Finalizes candidate paint name by attaching finish (SATIN, GLOSS, MATT) if found on separate lines
    String? finalizePaintName(String? name) {
      if (name == null || name.isEmpty) return null;
      var cleaned = _cleanPaintName(stripBrand(name));

      // Append finish type (SATIN, GLOSS, MATT) if present in rawLines but not yet in paint name
      if (cleaned.contains('ENAMEL') || cleaned.contains('EMULSION') || cleaned.contains('RUST SHIELD')) {
        if (!cleaned.contains('SATIN') && !cleaned.contains('GLOSS') && !cleaned.contains('MATT')) {
          for (final line in rawLines) {
            final u = line.trim().toUpperCase();
            if (u == 'SATIN' || u == 'GLOSS' || u == 'MATT' || u == 'MATTE' || u == 'HIGH GLOSS') {
              cleaned = '$cleaned $u';
              break;
            }
          }
        }
        if (cleaned.contains('RUST SHIELD') && !cleaned.contains('ENAMEL')) {
          for (final line in rawLines) {
            final u = line.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
            if (u == 'ENAMEL' || u == 'ENAMEL/') {
              cleaned = '$cleaned ENAMEL';
              break;
            }
          }
        }
      }

      // If a sub-brand is detected (e.g. "Apcolite", "Royale", "WeatherCoat", "Calista") and not yet in the name, prefix it
      if (subBrand != null) {
        final subUpper = subBrand.toUpperCase();
        if (!cleaned.toUpperCase().contains(subUpper) &&
            !(subUpper == 'TRACTOR' && cleaned.toUpperCase().contains('TRA EML')) &&
            !(subUpper == 'APEX ULTIMA' && cleaned.toUpperCase().contains('APEX')) &&
            !(subUpper == 'PGE ENAMEL' && cleaned.toUpperCase().contains('PGE'))) {
          cleaned = '$subUpper $cleaned';
        }
      }

      return cleaned;
    }

    // ── Pass 1b (HIGHEST PRIORITY): Brand anchor → product name from following lines
    // e.g. OCR: "ôpcolie," / "PREMIUM ENAMEL" / "SATIN" → Paint Name: "APCOLITE PREMIUM ENAMEL SATIN"
    for (int i = 0; i < effectiveLines.length; i++) {
      if (isBrandAnchorLine(effectiveLines[i]) && i + 1 < effectiveLines.length) {
        final buffer = StringBuffer();

        // If the anchor line was Apcolite (stylized or exact), prepend APCOLITE as the product sub-brand
        final cleanedAnchor = _cleanOcrToken(effectiveLines[i]);
        if (RegExp(r'^[o0a@]?[pP]+c[o0b@]?[pP]?l[i1l][t+l]?[e3]?[a-z]?$', caseSensitive: false).hasMatch(cleanedAnchor) ||
            cleanedAnchor.toUpperCase().contains('APCOLITE')) {
          buffer.write('APCOLITE');
        }
        for (int j = i + 1; j <= i + 4 && j < effectiveLines.length; j++) {
          final next = effectiveLines[j].trim();
          final nextUpper = next.toUpperCase();
          if (_isBrandOrBoilerplate(nextUpper)) break;
          if (nextUpper.contains('MRP') ||
              nextUpper.contains('MFD') ||
              nextUpper.contains('BEST BEFORE') ||
              nextUpper.contains('INCL') ||
              nextUpper.contains('WARRANTY') ||
              nextUpper.contains('YEARS') ||
              nextUpper.contains('YEAR') ||
              nextUpper.contains('ANTI') ||
              nextUpper.contains('FUNGAL') ||
              (nextUpper.contains('SHIELD') && !nextUpper.contains('RUST SHIELD')) ||
              nextUpper.contains('SOFT SHEEN') ||
              nextUpper.contains('HIGH') ||
              nextUpper.contains('COVERAGE') ||
              nextUpper.contains('PRIMER') ||
              nextUpper.contains('SURFACE') ||
              nextUpper.contains('HIDING') ||
              nextUpper.contains('SUPERIOR') ||
              nextUpper.contains('DRYING') ||
              nextUpper.contains('YELLOWING') ||
              nextUpper.contains('FINISH') ||
              nextUpper.contains('SHEEN') ||
              nextUpper.contains('GLOSS') ||
              nextUpper.contains('SATIN') ||
              nextUpper.contains('GUARD') ||
              nextUpper.contains('STAIN') ||
              nextUpper.contains('FOR METAL') ||
              nextUpper.contains('FOR WOOD') ||
              nextUpper.contains('ONLY FOR BASE') ||
              nextUpper.contains('ADD COLORANT') ||
              RegExp(r'^[\d\s₹+]+$').hasMatch(next) ||
              RegExp(r'^\d+L\s*(?:NET|HET)?$', caseSensitive: false).hasMatch(next) ||
              RegExp(r'^\d+Nos\.', caseSensitive: false).hasMatch(next)) break;
          if (buffer.isNotEmpty && RegExp(r'^[A-Z]{0,2}\d{2,5}$').hasMatch(nextUpper)) break;
          if (next.isNotEmpty) {
            if (buffer.isNotEmpty) buffer.write(' ');
            buffer.write(next);
          }
        }
        final candidate = buffer.toString().trim();
        if (candidate.isNotEmpty && candidate.length >= 3) {
          final finalized = finalizePaintName(candidate);
          if (finalized != null && finalized.isNotEmpty) return finalized;
        }
      }
    }

    // Pass 1: Check for known Paint Product Prefixes + Shade (single line or 2 adjacent lines)
    for (int i = 0; i < effectiveLines.length; i++) {
      final line = effectiveLines[i].trim().replaceAll(RegExp(r'\s+'), ' ');
      final upper = line.toUpperCase();

      if (_isBrandOrBoilerplate(upper)) continue;
      if (RegExp(r'^[\d\s]+$').hasMatch(line)) continue;
      if (line.length < 2) continue;

      // Skip lines that are purely a brand name
      if (isBrandAnchorLine(line)) continue;

      // Check if current line contains a known paint prefix
      for (final prefix in _paintPrefixes) {
        // Skip prefixes that are also brand tokens (e.g. APCOLITE, APCOFRESH)
        if (brandTokensUpper.contains(prefix)) continue;

        if (upper.contains(prefix)) {
          // If the line is just the prefix (e.g. "PGE", "APEX", "TRA EML")
          // and next line has the shade/color/finish (e.g. "SM GRY-G", "LF BROWN", "BASE PAINT", "PURWHT")
          if ((upper == prefix || line.length <= prefix.length + 3) && i + 1 < effectiveLines.length) {
            final nextLine = effectiveLines[i + 1].trim().replaceAll(RegExp(r'\s+'), ' ');
            final nextUpper = nextLine.toUpperCase();
            if (!_isBrandOrBoilerplate(nextUpper) &&
                !RegExp(r'^[\d\s]+$').hasMatch(nextLine) &&
                !nextUpper.contains('MRP') &&
                !nextUpper.contains('MFD') &&
                !nextUpper.contains('BEST BEFORE') &&
                nextLine.length >= 2) {
              final raw = _cleanPaintName('$line $nextLine');
              return finalizePaintName(raw);
            }
          }

          // Line already contains both the prefix and shade (e.g. "TRA EML SUPWHITE", "APEX AB2", "SATIN EN BASE PAINT")
          final candidate = _cleanPaintName(line);
          // If candidate is just the prefix (like "APEX", "TRA EML", "PGE"), search other lines for shade code
          if (candidate == 'APEX' || candidate == 'TRA EML' || candidate == 'PGE') {
            for (int k = 0; k < effectiveLines.length; k++) {
              if (k == i) continue;
              final otherLine = effectiveLines[k].trim();
              final otherUpper = otherLine.toUpperCase();
              if (otherUpper == 'AB2' ||
                  otherUpper == 'SUPWHITE' ||
                  RegExp(r'^(?:AB2|SUPWHITE|PURWHT|LF BROWN|SM GRY-G)\b').hasMatch(otherUpper)) {
                return finalizePaintName('$candidate $otherLine');
              }
            }
          }
          final finalized = finalizePaintName(candidate);
          if (finalized != null && finalized.isNotEmpty) return finalized;
        }
      }
    }


    // Pass 2: Generalized Pattern-based Extraction
    // Matches patterns like: [2-12 letter Product Word(s)] + [Shade/Color/Code/Base]
    // e.g. "PGE SM GRY-G", "SATIN EN BASE PAINT", "APCOFRESH PURWHT", "ROYALE SHYNE WHITE"
    final paintPatternRegex = RegExp(
      r'\b([A-Z]{2,12}(?:\s+[A-Z]{2,12}){0,2})\s+([A-Z0-9]+(?:-[A-Z0-9]+)?(?:\s+[A-Z0-9]+)*)\b',
    );

    for (int i = 0; i < effectiveLines.length; i++) {
      final line = effectiveLines[i].trim().replaceAll(RegExp(r'\s+'), ' ');
      final upper = line.toUpperCase();

      if (_isBrandOrBoilerplate(upper)) continue;
      if (upper.contains('MRP') ||
          upper.contains('MFD') ||
          upper.contains('SALE PRICE') ||
          upper.contains('BEST BEFORE')) {
        continue;
      }

      final match = paintPatternRegex.firstMatch(upper);
      if (match != null) {
        final candidate = match.group(0)!;
        if (!_isBrandOrBoilerplate(candidate) && candidate.length >= 5) {
          return finalizePaintName(candidate);
        }
      }
    }

    // Pass 3: Positional Fallback: Upper case text immediately following item code "0001 ..."
    for (int i = 0; i < effectiveLines.length; i++) {
      final line = effectiveLines[i].trim();
      if (RegExp(r'0001\s*\d{3,4}\s*\d{3}').hasMatch(line) && i + 1 < effectiveLines.length) {
        final candidate = effectiveLines[i + 1].trim().replaceAll(RegExp(r'\s+'), ' ');
        final upper = candidate.toUpperCase();
        if (!_isBrandOrBoilerplate(upper) &&
            !upper.contains('MRP') &&
            !upper.contains('MFD') &&
            candidate.length >= 3) {
          if (candidate.length <= 4 && i + 2 < effectiveLines.length) {
            final candidate2 = effectiveLines[i + 2].trim().replaceAll(RegExp(r'\s+'), ' ');
            return finalizePaintName('$candidate $candidate2');
          }
          return finalizePaintName(candidate);
        }
      }
    }

    return null;
  }

  /// Extracts short batch code when B.No prefix is absent (e.g., "K665", "GA261", "URB6")
  static String? _extractFallbackBatch(List<String> rawLines, String? mfd) {
    // 1. Prioritize standalone batch code on its own line (e.g. "URB6", "K665", "GA261", "K3068")
    for (final line in rawLines) {
      final trimmed = line.trim();
      final upper = trimmed.toUpperCase();
      if (RegExp(r'^[A-Z]{1,3}[0-9]{1,4}$').hasMatch(upper)) {
        if (upper != mfd && upper != 'NET' && upper != 'PGE' && upper != 'LTD') {
          return upper;
        }
      }
    }

    // 2. Scan lines not containing Mfd date
    for (final line in rawLines) {
      final upper = line.toUpperCase();
      if (mfd != null && upper.contains(mfd)) continue;
      if (upper.contains('MFD') || upper.contains('MANUFACTURED')) continue;

      final match = RegExp(r'\b([A-Z]{1,3}[0-9]{1,4}|[A-Z][0-9]{3,4}|[A-Z]{2}[0-9]{3})\b').firstMatch(upper);
      if (match != null) {
        final code = match.group(1);
        if (code != mfd && code != 'NET' && code != 'PGE' && code != 'LTD') {
          return code;
        }
      }
    }
    return null;
  }

  /// Extracts BASE information if present on the label (e.g. "BASE : 3.6L", "BASE 1", "WHITE BASE")
  static String? _extractBase(List<String> rawLines, {String? paintName}) {
    // 1. Explicit key-value: "BASE : ...", "BASE - ...", "PART A (BASE) : ..."
    for (int i = 0; i < rawLines.length; i++) {
      final line = rawLines[i].trim();

      // Check for "PART A : BASE" or "PART A - BASE"
      final partAMatch = RegExp(
        r'^PART\s*[A1]\s*[:.-]?\s*(BASE.*)$',
        caseSensitive: false,
      ).firstMatch(line);
      if (partAMatch != null && partAMatch.group(1) != null) {
        return partAMatch.group(1)!.trim();
      }

      // Check for explicit "BASE :" or "BASE -"
      final match = RegExp(
        r'^(?:PART\s*[A1]\s*[:.-]?\s*)?BASE\s*[:.-]\s*(.+)$',
        caseSensitive: false,
      ).firstMatch(line);

      if (match != null && match.group(1) != null) {
        final val = match.group(1)!.trim();
        if (val.isNotEmpty && val.toUpperCase() != 'PAINT') {
          return val;
        }
      }

      // Check for inline "BASE: <value>"
      final inlineMatch = RegExp(
        r'\bBASE\s*[:.-]\s*([A-Za-z0-9.]+(?:\s+[A-Za-z0-9.]+){0,3})',
        caseSensitive: false,
      ).firstMatch(line);
      if (inlineMatch != null && inlineMatch.group(1) != null) {
        final val = inlineMatch.group(1)!.trim();
        if (val.isNotEmpty && val.toUpperCase() != 'PAINT') {
          return val;
        }
      }

      // Standalone "BASE" line
      if (RegExp(r'^(?:PART\s*[A1]\s*[:.-]?\s*)?BASE$', caseSensitive: false).hasMatch(line)) {
        if (i + 1 < rawLines.length) {
          final nextLine = rawLines[i + 1].trim();
          final nextUpper = nextLine.toUpperCase();
          if (nextLine.isNotEmpty &&
              !_isBrandOrBoilerplate(nextUpper) &&
              !nextUpper.contains('MRP') &&
              !nextUpper.contains('MFD') &&
              !nextUpper.contains('UNIT SALE') &&
              !nextUpper.contains('HARDENER')) {
            return nextLine;
          }
        }
        return 'BASE';
      }

      // Base category / shade base, e.g. "BASE 1", "BASE 2", "BASE 3", "BASE WHITE", "WHITE BASE", "DEEP BASE", "CLEAR BASE", "ACCENT BASE"
      final baseTypeMatch = RegExp(
        r'\b(?:BASE\s*(?:[1-4]|WHITE|CLEAR|DEEP|ACCENT|[A-Z0-9]+)|(?:WHITE|CLEAR|DEEP|ACCENT)\s*BASE)\b',
        caseSensitive: false,
      ).firstMatch(line);

      if (baseTypeMatch != null) {
        final found = baseTypeMatch.group(0)!.trim();
        // If it's part of the paint name (like "SATIN EN BASE PAINT"), only extract if explicitly distinct
        if (paintName == null || !paintName.toUpperCase().contains(found.toUpperCase()) || found.toUpperCase() != paintName.toUpperCase()) {
          return found;
        }
      }
    }
    return null;
  }

  /// Extracts HARDENER information if present on the label (e.g. "HARDENER: 400ml", "HARDENER : PU HARDENER")
  static String? _extractHardener(List<String> rawLines) {
    for (int i = 0; i < rawLines.length; i++) {
      final line = rawLines[i].trim();
      final upper = line.toUpperCase();

      // Skip lines not containing HARDENER
      if (!upper.contains('HARDENER')) continue;

      // Check for "PART B : HARDENER", "CATALYST : HARDENER"
      final partBMatch = RegExp(
        r'^(?:PART\s*[B2]|CATALYST)\s*[:.-]?\s*(HARDENER.*)$',
        caseSensitive: false,
      ).firstMatch(line);
      if (partBMatch != null && partBMatch.group(1) != null) {
        return partBMatch.group(1)!.trim();
      }

      // 1. Explicit key-value like "HARDENER : ...", "HARDENER - ...", "PART B (HARDENER) : ..."
      final match = RegExp(
        r'^(?:PART\s*[B2]\s*[:.-]?\s*)?(?:CATALYST\s*/\s*)?HARDENER\s*[:.-]\s*(.+)$',
        caseSensitive: false,
      ).firstMatch(line);

      if (match != null && match.group(1) != null) {
        final val = match.group(1)!.trim();
        if (val.isNotEmpty) {
          return val;
        }
      }

      // 2. Inline "HARDENER: <value>"
      final inlineMatch = RegExp(
        r'\bHARDENER\s*[:.-]\s*([A-Za-z0-9.]+(?:\s+[A-Za-z0-9.]+){0,3})',
        caseSensitive: false,
      ).firstMatch(line);
      if (inlineMatch != null && inlineMatch.group(1) != null) {
        final val = inlineMatch.group(1)!.trim();
        if (val.isNotEmpty) {
          return val;
        }
      }

      // 3. Standalone "HARDENER" line
      if (RegExp(r'^(?:PART\s*[B2]\s*[:.-]?\s*)?(?:CATALYST\s*/\s*)?HARDENER$', caseSensitive: false).hasMatch(line)) {
        if (i + 1 < rawLines.length) {
          final nextLine = rawLines[i + 1].trim();
          final nextUpper = nextLine.toUpperCase();
          if (nextLine.isNotEmpty &&
              !_isBrandOrBoilerplate(nextUpper) &&
              !nextUpper.contains('MRP') &&
              !nextUpper.contains('MFD') &&
              !nextUpper.contains('UNIT SALE') &&
              !nextUpper.contains('BASE')) {
            return nextLine;
          }
        }
        return 'HARDENER';
      }

      // 4. Line with Hardener details (e.g., "PU HARDENER 400ml", "HARDENER 0.4L", "CATALYST / HARDENER")
      return line;
    }
    return null;
  }
}
