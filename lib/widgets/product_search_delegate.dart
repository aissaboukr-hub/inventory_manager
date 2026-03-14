import 'package:flutter/material.dart';
import '../models/product.dart';
import '../core/database/database_service.dart';
import '../core/theme.dart';

class ProductSearchDelegate extends SearchDelegate<Product?> {
  final void Function(Product product) onProductSelected;

  ProductSearchDelegate({required this.onProductSelected});

  @override
  String get searchFieldLabel => 'Rechercher par nom, code ou barcode…';

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    if (query.length < 2) {
      return Center(
        child: Text(
          'Saisissez au moins 2 caractères',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return FutureBuilder<List<Product>>(
      future: DatabaseService.instance.searchProducts(query),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final results = snap.data ?? [];
        if (results.isEmpty) {
          return Center(
            child: Text(
              'Aucun produit trouvé pour "$query"',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          );
        }
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (_, i) {
            final p = results[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                child: Text(
                  p.code.length > 3
                      ? p.code.substring(0, 3)
                      : p.code,
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(p.designation),
              subtitle: Text('${p.code}  •  ${p.barcode}'),
              onTap: () {
                close(context, p);
                onProductSelected(p);
              },
            );
          },
        );
      },
    );
  }
}
