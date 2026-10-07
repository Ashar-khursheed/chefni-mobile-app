import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../repositories/recipe_card_repository.dart';

/// Builds branded, print-ready PDFs — a single recipe card or a cookbook of
/// several — and hands them to the OS share sheet.
class RecipePdfExporter {
  static const _coral = PdfColor.fromInt(0xFFE85A7E);
  static const _ink = PdfColor.fromInt(0xFF2E2029);
  static const _muted = PdfColor.fromInt(0xFF5F7284);

  /// A single recipe: ingredients at the given scale, then the method.
  static Future<Uint8List> buildRecipeCardPdf({
    required String title,
    required String chefName,
    required int servings,
    required double baseWeightGrams,
    required List<Map<String, dynamic>> ingredients,
    required List<String> steps,
    String? brandName,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _brandHeader(brandName),
            pw.SizedBox(height: 14),
            pw.Text(title,
                style: pw.TextStyle(
                    fontSize: 24, fontWeight: pw.FontWeight.bold, color: _ink)),
            pw.SizedBox(height: 4),
            pw.Text(
              'By $chefName · $servings servings · ${baseWeightGrams.toStringAsFixed(0)}g base',
              style: const pw.TextStyle(fontSize: 11, color: _muted),
            ),
            pw.SizedBox(height: 18),
            _sectionTitle('Ingredients'),
            pw.SizedBox(height: 6),
            _ingredientTable(ingredients),
            if (steps.isNotEmpty) ...[
              pw.SizedBox(height: 18),
              _sectionTitle('Method'),
              pw.SizedBox(height: 6),
              _stepsList(steps),
            ],
            pw.Spacer(),
            _footer(),
          ],
        ),
      ),
    );
    return doc.save();
  }

  /// Several recipe cards bound into one cookbook, with a cover page.
  static Future<Uint8List> buildCookbookPdf({
    required String cookbookTitle,
    required String chefName,
    required List<RecipeCard> recipes,
    bool includeCosts = true,
    String? brandName,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            _brandHeader(brandName),
            pw.SizedBox(height: 40),
            pw.Text(cookbookTitle,
                style: pw.TextStyle(
                    fontSize: 30, fontWeight: pw.FontWeight.bold, color: _ink)),
            pw.SizedBox(height: 8),
            pw.Text('By $chefName',
                style: const pw.TextStyle(fontSize: 13, color: _muted)),
            pw.SizedBox(height: 4),
            pw.Text('${recipes.length} recipes',
                style: const pw.TextStyle(fontSize: 11, color: _muted)),
          ],
        ),
      ),
    );

    for (final card in recipes) {
      final ingredients = card.ingredients
          .map((i) => {
                'name': i.name,
                'quantity': i.quantity,
                'unit': i.unit,
                'cost': includeCosts ? i.effectiveCost : null,
              })
          .toList();

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(card.title,
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold, color: _ink)),
              pw.SizedBox(height: 4),
              pw.Text(
                '${card.servings} servings'
                '${card.totalTimeMins != null ? ' · ${card.totalTimeMins} min' : ''}'
                '${includeCosts ? ' · ${card.formatCost(card.totalCost)} total' : ''}',
                style: const pw.TextStyle(fontSize: 11, color: _muted),
              ),
              pw.SizedBox(height: 16),
              _sectionTitle('Ingredients'),
              pw.SizedBox(height: 6),
              _ingredientTable(ingredients, showCost: includeCosts),
              if (card.steps.isNotEmpty) ...[
                pw.SizedBox(height: 16),
                _sectionTitle('Method'),
                pw.SizedBox(height: 6),
                _stepsList(card.steps),
              ],
            ],
          ),
        ),
      );
    }

    return doc.save();
  }

  static pw.Widget _brandHeader(String? brandName) => pw.Text(
        (brandName ?? 'CHEFNI AI').toUpperCase(),
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: _coral,
          letterSpacing: 1.5,
        ),
      );

  static pw.Widget _sectionTitle(String text) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 4),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _coral, width: 1.2)),
        ),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold, color: _ink)),
      );

  static pw.Widget _ingredientTable(
    List<Map<String, dynamic>> ingredients, {
    bool showCost = false,
  }) {
    return pw.Table(
      border: const pw.TableBorder(
        bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFEAE3E6), width: 0.5),
        horizontalInside: pw.BorderSide(color: PdfColor.fromInt(0xFFEAE3E6), width: 0.5),
      ),
      columnWidths: showCost
          ? const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(1.4), 2: pw.FlexColumnWidth(1.2)}
          : const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(1.4)},
      children: [
        for (final ing in ingredients)
          pw.TableRow(children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 5),
              child: pw.Text('${ing['name']}',
                  style: const pw.TextStyle(fontSize: 10.5, color: _ink)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 5),
              child: pw.Text('${ing['quantity']} ${ing['unit'] ?? ''}',
                  style: const pw.TextStyle(fontSize: 10.5, color: _muted)),
            ),
            if (showCost)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 5),
                child: pw.Text(
                  ing['cost'] != null ? 'Rs ${(ing['cost'] as num).toStringAsFixed(0)}' : '',
                  style: const pw.TextStyle(fontSize: 10.5, color: _coral),
                ),
              ),
          ]),
      ],
    );
  }

  static pw.Widget _stepsList(List<String> steps) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 16,
                    child: pw.Text('${i + 1}.',
                        style: pw.TextStyle(
                            fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: _coral)),
                  ),
                  pw.Expanded(
                    child: pw.Text(steps[i],
                        style: const pw.TextStyle(fontSize: 10.5, color: _ink)),
                  ),
                ],
              ),
            ),
        ],
      );

  static pw.Widget _footer() => pw.Container(
        alignment: pw.Alignment.center,
        padding: const pw.EdgeInsets.only(top: 10),
        child: pw.Text('Chefni AI — Fine. Fast. Fab.',
            style: const pw.TextStyle(fontSize: 9, color: _muted)),
      );

  /// Hands the PDF to the OS share sheet (or a print dialog on desktop/web).
  static Future<void> share(Uint8List bytes, String filename) {
    return Printing.sharePdf(bytes: bytes, filename: filename);
  }
}
