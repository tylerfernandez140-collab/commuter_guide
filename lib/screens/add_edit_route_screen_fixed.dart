Widget _buildMapSection() {
    // Check if ORS API key is available
    final hasApiKey = dotenv.env['ORS_API_KEY'] != null && dotenv.env['ORS_API_KEY']!.isNotEmpty;
    
    return Stack(
      children: [
        if (hasApiKey)
          Container(
            child: _useGoogleMaps 
                ? gmap.GoogleMap(
                  key: ValueKey('google_map_${_waypoints.length}_${_waypoints.isNotEmpty ? _waypoints.first.latitude : 0}_${_waypoints.length > 1 ? _waypoints.last.latitude : 0}'),
                  initialCameraPosition: gmap.CameraPosition(
                    target: _waypoints.isNotEmpty
                        ? gmap.LatLng(_waypoints.first.latitude, _waypoints.first.longitude)
                        : gmap.LatLng(_paranaqueCenter.latitude, _paranaqueCenter.longitude),
                    zoom: 13.5,
                  ),
                  onMapCreated: (c) {
                    _gmapController = c;
                    debugPrint('GoogleMap controller created');
                  },
                  onTap: (pos) => _handleMapTap(LatLng(pos.latitude, pos.longitude)),
                  minMaxZoomPreference: const gmap.MinMaxZoomPreference(2.0, 18.0),
                  markers: {
                    if (_waypoints.isNotEmpty && _greenMarkerIcon != null)
                      gmap.Marker(
                        markerId: const gmap.MarkerId('start'),
                        position: gmap.LatLng(_waypoints.first.latitude, _waypoints.first.longitude),
                        icon: _greenMarkerIcon!,
                        infoWindow: gmap.InfoWindow(
                          title: ' START POINT',
                          snippet: 'Origin: ${_startController.text}',
                        ),
                      ),
                    if (_waypoints.length > 1 && _redMarkerIcon != null)
                      gmap.Marker(
                        markerId: const gmap.MarkerId('end'),
                        position: gmap.LatLng(_waypoints.last.latitude, _waypoints.last.longitude),
                        icon: _redMarkerIcon!,
                        infoWindow: gmap.InfoWindow(
                          title: ' END POINT',
                          snippet: 'Destination: ${_endController.text}',
                        ),
                      ),
                  },
                  polylines: {
                    if (_displayRoute.isNotEmpty)
                      gmap.Polyline(
                        polylineId: const gmap.PolylineId('route'),
                        points: _displayRoute
                            .map((p) => gmap.LatLng(p.latitude, p.longitude))
                            .toList(),
                        color: Theme.of(context).primaryColor,
                        width: 5,
                      ),
                  },
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                  zoomControlsEnabled: false,
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  myLocationEnabled: false,
                )
                : FlutterMap(
                  mapController: _fallbackMapController,
                  options: MapOptions(
                    initialCenter: _waypoints.isNotEmpty ? _waypoints.first : _paranaqueCenter,
                    initialZoom: 13.5,
                    onTap: (tapPosition, point) => _handleMapTap(point),
                    minZoom: 2.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.byahero',
                    ),
                    PolylineLayer(
                      polylines: [
                        if (_displayRoute.isNotEmpty)
                          Polyline(
                            points: _displayRoute,
                            strokeWidth: 5.0,
                            color: Theme.of(context).primaryColor,
                          ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        if (_waypoints.isNotEmpty)
                          Marker(
                            point: _waypoints.first,
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        if (_waypoints.length > 1)
                          Marker(
                            point: _waypoints.last,
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.flag,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
          ),
        if (_isRouting)
          Positioned(
            top: 20,
            left: 16,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(_statusMessage, style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        Positioned(
          top: 20,
          right: 16,
          child: Material(
            elevation: 8, // Higher elevation to be on top
            borderRadius: BorderRadius.circular(30),
            color: Colors.transparent,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {}, // Prevent tap through
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: "undo",
                    onPressed: _undoPoint,
                    backgroundColor: Colors.white,
                    tooltip: 'Undo last point',
                    child: Icon(Icons.undo, color: Colors.black87),
                  ),
                  SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: "clear",
                    onPressed: _clearPoints,
                    backgroundColor: Colors.white,
                    tooltip: 'Clear route',
                    child: Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_waypoints.isEmpty)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                "Tap map to start drawing route",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
