enum ParcelStatus { booked, loaded, inTransit, arrived, collected }

ParcelStatus parcelStatusFromApi(String value) {
  return switch (value) {
    'booked' => ParcelStatus.booked,
    'loaded' => ParcelStatus.loaded,
    'in_transit' => ParcelStatus.inTransit,
    'arrived' => ParcelStatus.arrived,
    'collected' => ParcelStatus.collected,
    _ => throw FormatException('Unknown parcel status: $value'),
  };
}