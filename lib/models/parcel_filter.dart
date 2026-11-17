// the filters on the Parcels screen, with the names the API uses for them
enum ParcelFilter {
  all('all', 'All'),
  booked('booked', 'Booked'),
  onTheWay('on_the_way', 'On the way'),
  arrived('arrived', 'Arrived');

  const ParcelFilter(this.apiName, this.label);

  final String apiName;
  final String label;
}