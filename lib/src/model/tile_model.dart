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
  final List<TilePoint>? modelPoints;
  final List<TileLine>? modelLines;
  final List<TilePolygon>? modelPolygons;
  List<Offset>? _points;
  List<BoundedPath>? _paths;
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
    var points1 = _points;
    final mPoints = modelPoints;
    if (points1 == null && mPoints != null) {
      final uiGeometry = UiGeometry();
      points1 = mPoints
          .map((e) => uiGeometry.createPoint(e))
          .toList(growable: false);
      _points = points1;
    }
    return points1 ?? List.empty();
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
    final mPolygons = modelPolygons;

    if (_paths == null && mLines != null) {
      assert(type == TileFeatureType.linestring);
      final uiGeometry = UiGeometry();
      _paths = mLines
          .map((e) => BoundedPath(uiGeometry.createLine(e)))
          .toList(growable: false);
    } else if (_paths == null && mPolygons != null) {
      assert(type == TileFeatureType.polygon);
      final uiGeometry = UiGeometry();
      _paths = mPolygons
          .map((e) => BoundedPath(uiGeometry.createPolygon(e)))
          .toList(growable: false);
    }
    return _paths ?? List.empty();
  }
}

enum TileFeatureType { point, linestring, polygon, background, none }
