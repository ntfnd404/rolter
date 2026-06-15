import 'package:rolter/src/model/route_node.dart';
import 'package:rolter/src/model/route_registry.dart';

/// A self-contained, mountable feature router.
///
/// Bundles a mount [name], the [mountDecoder] that builds the shell node for
/// that name, and the feature-owned [registry] that decodes the node's subtree.
/// Compose several with [composeFeatureRouters] so each feature owns its own
/// URL-name namespace — ideal when features ship as separate packages.
class FeatureRouter<R extends RouteNode> {
  /// Creates a feature router mounted under [name].
  const FeatureRouter({
    required this.name,
    required this.mountDecoder,
    required this.registry,
  });

  /// The mount name in the parent (root) registry.
  final String name;

  /// Builds the shell node for [name]; its children come from [registry].
  final RouteDecoder<R> mountDecoder;

  /// Decodes this feature's subtree (its own route-name namespace).
  final RouteRegistry<R> registry;
}

/// Builds a root [RouteRegistry] from top-level [decoders] plus a set of
/// [features], each mounted under its [FeatureRouter.name] (its `mountDecoder`
/// builds the shell, its `registry` decodes the subtree). [fallback] handles
/// unknown top-level names.
///
/// Flat decoders and mounted features coexist; a feature's internal route names
/// are isolated from the root and from other features.
RouteRegistry<R> composeFeatureRouters<R extends RouteNode>({
  required R Function(Uri attempted) fallback,
  Map<String, RouteDecoder<R>> decoders = const {},
  List<FeatureRouter<R>> features = const [],
}) {
  final mergedDecoders = <String, RouteDecoder<R>>{
    ...decoders,
    for (final feature in features) feature.name: feature.mountDecoder,
  };
  final children = <String, RouteRegistry<R>>{
    for (final feature in features) feature.name: feature.registry,
  };

  return RouteRegistry<R>(
    mergedDecoders,
    fallback: fallback,
    children: children,
  );
}
