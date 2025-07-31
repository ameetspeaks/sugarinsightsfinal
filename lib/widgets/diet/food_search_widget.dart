import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/food_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FoodSearchWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onFoodSelected;
  final String? initialValue;

  const FoodSearchWidget({
    super.key,
    required this.onFoodSelected,
    this.initialValue,
  });

  @override
  State<FoodSearchWidget> createState() => _FoodSearchWidgetState();
}

class _FoodSearchWidgetState extends State<FoodSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FoodService _foodService = FoodService(Supabase.instance.client);
  
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _searchController.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchFood(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _foodService.searchFoodItems(query);
      setState(() {
        _searchResults = results;
        _showResults = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _showResults = false;
        _isLoading = false;
      });
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching food: $e')),
        );
      }
    }
  }

  void _onFoodSelected(Map<String, dynamic> foodItem) {
    widget.onFoodSelected(foodItem);
    setState(() {
      _searchController.text = foodItem['name'];
      _showResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Food',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for food items...',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.search, color: Colors.grey),
            ),
            onChanged: (value) {
              _searchFood(value);
            },
            onTap: () {
              if (_searchResults.isNotEmpty) {
                setState(() {
                  _showResults = true;
                });
              }
            },
          ),
        ),
        if (_showResults && _searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final foodItem = _searchResults[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.restaurant,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    foodItem['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '${foodItem['calories_per_100g'] ?? 0} kcal per 100g',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  trailing: Text(
                    '${foodItem['carbs_per_100g']?.toStringAsFixed(1) ?? '0'}g carbs',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  onTap: () => _onFoodSelected(foodItem),
                );
              },
            ),
          ),
        if (_showResults && _searchResults.isEmpty && !_isLoading)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Text(
              'No food items found. Try a different search term.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }
} 