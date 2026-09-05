import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../shop_master/shop_master_models.dart';
import '../shop_master/shop_master_service.dart';
import 'route_master_models.dart';

Future<void> showRouteShopsDialog(BuildContext context, {required RouteMaster route, required ShopMasterService shopService}) {
  return showDialog(
    context: context,
    builder: (context) => _RouteShopsDialog(route: route, shopService: shopService),
  );
}

class _RouteShopsDialog extends StatefulWidget {
  const _RouteShopsDialog({required this.route, required this.shopService});
  final RouteMaster route;
  final ShopMasterService shopService;

  @override
  State<_RouteShopsDialog> createState() => _RouteShopsDialogState();
}

class _RouteShopsDialogState extends State<_RouteShopsDialog> {
  bool _loading = true;
  String? _error;
  List<ShopMaster> _shops = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await widget.shopService.getPaged(1, routeId: widget.route.routeId, pageSize: 100);
      if (!mounted) return;
      setState(() {
        _shops = result.items;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Customers on ${widget.route.routeName}'),
      content: SizedBox(
        width: double.maxFinite,
        child: _loading
            ? const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()))
            : _error != null
                ? Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))
                : _shops.isEmpty
                    ? const Text('No customers assigned to this route.')
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _shops.length,
                        itemBuilder: (context, index) {
                          final shop = _shops[index];
                          return ListTile(
                            leading: const Icon(Icons.store_outlined),
                            title: Text(shop.shopName),
                            subtitle: Text(
                              [shop.ownerName, shop.phone].where((v) => v != null && v.isNotEmpty).join(' · ').isEmpty
                                  ? 'No owner listed'
                                  : [shop.ownerName, shop.phone].where((v) => v != null && v.isNotEmpty).join(' · '),
                            ),
                          );
                        },
                      ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
      ],
    );
  }
}
