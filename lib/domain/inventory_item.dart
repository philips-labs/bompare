class InventoryItem {
  final String name;
  final String version;
  final Set<String> licenses;

  InventoryItem(this.name, this.version, {this.licenses = const {}});
}
