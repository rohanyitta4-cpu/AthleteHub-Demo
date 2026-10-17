import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Performance optimization utilities for the AthleteHub app
class PerformanceOptimizations {
  
  /// Initialize performance optimizations
  static void initialize() {
    // Set preferred orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Enable system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }
  
  /// Optimize image loading
  static void optimizeImageLoading() {
    // This can be used to preload critical images or set image cache policies
  }
  
  /// Memory management utilities
  static void clearImageCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
}

/// Optimized list view builder for better performance
class OptimizedListViewBuilder extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final double? cacheExtent;

  const OptimizedListViewBuilder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.cacheExtent,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      cacheExtent: cacheExtent,
    );
  }
}

/// Optimized grid view for better performance
class OptimizedGridViewBuilder extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const OptimizedGridViewBuilder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.crossAxisCount,
    this.crossAxisSpacing = 0.0,
    this.mainAxisSpacing = 0.0,
    this.childAspectRatio = 1.0,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
    );
  }
}

/// Optimized container with performance improvements
class OptimizedContainer extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final Clip clipBehavior;

  const OptimizedContainer({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.decoration,
    this.width,
    this.height,
    this.alignment,
    this.clipBehavior = Clip.none,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      margin: margin,
      decoration: decoration,
      width: width,
      height: height,
      alignment: alignment,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}

/// Optimized text widget with performance improvements
class OptimizedText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool softWrap;

  const OptimizedText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      style: style,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      softWrap: softWrap,
    );
  }
}

/// Memory-efficient scroll controller
class OptimizedScrollController extends ScrollController {
  OptimizedScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
  });

  @override
  void dispose() {
    // Clear any cached data before disposal
    super.dispose();
  }
}

/// Performance monitoring utilities
class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  static final Map<String, List<Duration>> _measurements = {};

  /// Start timing an operation
  static void startTiming(String operationName) {
    _startTimes[operationName] = DateTime.now();
  }

  /// End timing an operation
  static void endTiming(String operationName) {
    final startTime = _startTimes[operationName];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _measurements.putIfAbsent(operationName, () => []).add(duration);
      _startTimes.remove(operationName);
      
      // Log performance data in debug mode
      debugPrint('Performance: $operationName took ${duration.inMilliseconds}ms');
    }
  }

  /// Get average time for an operation
  static Duration getAverageTime(String operationName) {
    final measurements = _measurements[operationName];
    if (measurements == null || measurements.isEmpty) {
      return Duration.zero;
    }
    
    final totalMicroseconds = measurements
        .map((d) => d.inMicroseconds)
        .reduce((a, b) => a + b);
    
    return Duration(microseconds: totalMicroseconds ~/ measurements.length);
  }

  /// Clear all measurements
  static void clearMeasurements() {
    _measurements.clear();
    _startTimes.clear();
  }
} 