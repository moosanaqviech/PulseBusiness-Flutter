// pulse_business/lib/widgets/business_autocomplete_field.dart

import 'package:flutter/material.dart';
import '../services/google_places_service.dart';

/// A text field with Google Places autocomplete dropdown.
/// When a user types their business name, suggestions appear.
/// On selection, calls [onPlaceSelected] with full PlaceDetails.
class BusinessAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final GooglePlacesService placesService;
  final Function(PlaceDetails) onPlaceSelected;
  final double? userLat;
  final double? userLng;

  const BusinessAutocompleteField({
    super.key,
    required this.controller,
    required this.placesService,
    required this.onPlaceSelected,
    this.userLat,
    this.userLng,
  });

  @override
  State<BusinessAutocompleteField> createState() =>
      _BusinessAutocompleteFieldState();
}

class _BusinessAutocompleteFieldState extends State<BusinessAutocompleteField> {
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  
  List<PlacePrediction> _predictions = [];
  bool _isLoading = false;
  bool _isSelecting = false; // Prevents re-triggering search after selection
  bool _isFetchingDetails = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      // Small delay to allow tap on dropdown item to register
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  void _onTextChanged() {
    if (_isSelecting) return;

    final query = widget.controller.text.trim();
    if (query.length < 2) {
      _removeOverlay();
      setState(() => _predictions = []);
      return;
    }

    setState(() => _isLoading = true);

    widget.placesService.searchWithDebounce(
      query: query,
      lat: widget.userLat,
      lng: widget.userLng,
      onResults: (results) {
        if (!mounted) return;
        setState(() {
          _predictions = results;
          _isLoading = false;
        });
        if (results.isNotEmpty) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      },
    );
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: _getFieldWidth(),
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60), // Below the text field
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            shadowColor: Colors.black26,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 280),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildDropdownContent(),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildDropdownContent() {
    if (_isFetchingDetails) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.deepPurple.shade400,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Getting your business details...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _predictions.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 52,
        color: Colors.grey.shade100,
      ),
      itemBuilder: (context, i) {
        final prediction = _predictions[i];
        return InkWell(
          onTap: () => _onPredictionSelected(prediction),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Business icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    color: Colors.deepPurple.shade400,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Business name + address
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prediction.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        prediction.secondaryText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.north_west_rounded,
                  size: 16,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onPredictionSelected(PlacePrediction prediction) async {
    // Set selecting flag so text change doesn't re-trigger search
    _isSelecting = true;
    widget.controller.text = prediction.name;

    // Show loading state in dropdown
    setState(() => _isFetchingDetails = true);
    _showOverlay(); // Rebuild overlay with loading state

    // Fetch full details
    final details = await widget.placesService.getPlaceDetails(prediction.placeId);

    if (!mounted) return;
    
    setState(() => _isFetchingDetails = false);
    _removeOverlay();

    if (details != null) {
      widget.onPlaceSelected(details);
      
      // Brief delay then allow manual editing again
      Future.delayed(const Duration(milliseconds: 500), () {
        _isSelecting = false;
      });
    } else {
      _isSelecting = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load business details. You can enter info manually.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  double _getFieldWidth() {
    final renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size.width ?? 300;
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          labelText: 'Business Name *',
          prefixIcon: const Icon(Icons.business),
          suffixIcon: _isLoading
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.deepPurple.shade300,
                    ),
                  ),
                )
              : widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey.shade400),
                      onPressed: () {
                        widget.controller.clear();
                        _isSelecting = false;
                        _removeOverlay();
                      },
                    )
                  : null,
          hintText: 'Start typing your business name...',
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Business name is required';
          }
          return null;
        },
      ),
    );
  }
  
}