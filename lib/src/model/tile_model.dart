import 'dart:ui';

import 'geometry_model.dart';
import 'geometry_model_ui.dart';

class Tile {
  final List<TileLayer> layers;

  Tile({required this.layers});
}

class TileLayer {
  final String name;
  final int extent;
  final List<TileFeature> features;

  TileLayer({required this.name, required this.extent, required this.features});
}

class BoundedPath {
  final Path path;
  Rect? _bounds;
  List<PathMetric>? _pathMetrics;

  BoundedPath(this.path);

  Rect get bounds {
    var bounds = _bounds;
    if (bounds == null) {
      bounds = path.getBounds();
      _bounds = bounds;
    }
    return bounds;
  }

  List<PathMetric> get pathMetrics {
    var pathMetrics = _pathMetrics;
    if (pathMetrics == null) {
      pathMetrics = path.computeMetrics().toList(growable: false);
      _pathMetrics = pathMetrics;
    }
    return pathMetrics;
  }
}

class TileFeature {
  final TileFeatureType type;
  final Map<String, dynamic> properties;
  List<TilePoint>? modelPoints;
  List<TileLine>? modelLines;
  List<TilePolygon>? modelPolygons;
  late List<Offset> _points;
  late List<BoundedPath> _paths;
  BoundedPath? _compoundPath;

  TileFeature(
      {required this.type,
      required this.properties,
      required List<TilePoint>? points,
      required List<TileLine>? lines,
      required List<TilePolygon>? polygons})
      : modelPoints = points,
        modelLines = lines,
        modelPolygons = polygons;

  List<Offset> get points {
    if (type != TileFeatureType.point) {
      throw StateError('Feature does not have points');
    }
    final mPoints = modelPoints;
    if (mPoints != null) {
      final uiGeometry = UiGeometry();
      _points = mPoints
          .map((e) => uiGeometry.createPoint(e))
          .toList(growable: false);
      modelPoints = null;
    }
    return _points;
  }

  bool get hasPaths =>
      type == TileFeatureType.linestring || type == TileFeatureType.polygon;

  bool get hasPoints => type == TileFeatureType.point;

  BoundedPath get compoundPath {
    var compoundPath = _compoundPath;
    if (compoundPath == null) {
      final paths = this.paths;
      if (paths.length == 1) {
        compoundPath = paths.first;
      } else {
        final linesPath = Path();
        for (final line in paths) {
          linesPath.addPath(line.path, Offset.zero);
        }
        compoundPath = BoundedPath(linesPath);
      }
      _compoundPath = compoundPath;
    }
    return compoundPath;
  }

  List<BoundedPath> get paths {
    if (type == TileFeatureType.point) {
      throw StateError('Cannot get paths from a point feature');
    }
    final mLines = modelLines;
    if (mLines != null) {
      assert(type == TileFeatureType.linestring);
      final uiGeometry = UiGeometry();
      _paths = mLines
          .map((e) => BoundedPath(uiGeometry.createLine(e)))
          .toList(growable: false);
      modelLines = null;
    }
    final mPolygons = modelPolygons;
    if (mPolygons != null) {
      assert(type == TileFeatureType.polygon);
      final uiGeometry = UiGeometry();
      _paths = mPolygons
          .map((e) => BoundedPath(uiGeometry.createPolygon(e)))
          .toList(growable: false);
      modelPolygons = null;
    }
    return _paths;
  }
}

enum TileFeatureType { point, linestring, polygon, background, none }
