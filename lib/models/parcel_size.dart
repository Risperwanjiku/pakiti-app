enum ParcelSize {
  small('Small', 'Envelope or documents'),
  medium('Medium', 'Carton up to 10 kg'),
  large('Large', 'Sack or crate over 10 kg');

  const ParcelSize(this.label, this.hint);

  final String label;
  final String hint;
}