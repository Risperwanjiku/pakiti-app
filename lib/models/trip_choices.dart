class RouteChoice {
  const RouteChoice({
    required this.id,
    required this.from,
    required this.to,
    required this.minutes,
    required this.waiting,
  });

  factory RouteChoice.fromJson(Map<String, dynamic> json) {
    return RouteChoice(
      id: json['route_id'] as int,
      from: json['from'] as String,
      to: json['to'] as String,
      minutes: json['minutes'] as int,
      waiting: json['waiting'] as int,
    );
  }

  final int id;
  final String from;
  final String to;
  final int minutes;

  // parcels booked for this route that are not on a vehicle yet
  final int waiting;

  String get name => '$from to $to';
}

class VehicleChoice {
  const VehicleChoice({
    required this.id,
    required this.regNumber,
    this.fleetNumber,
    required this.busy,
  });

  factory VehicleChoice.fromJson(Map<String, dynamic> json) {
    return VehicleChoice(
      id: json['vehicle_id'] as int,
      regNumber: json['reg_number'] as String,
      fleetNumber: json['fleet_number'] as String?,
      busy: json['busy'] as bool,
    );
  }

  final int id;
  final String regNumber;
  final String? fleetNumber;

  // on another trip that hasn't ended
  final bool busy;
}

// what the Start a trip screen can offer, and what it starts on
class TripChoices {
  const TripChoices({
    required this.routes,
    required this.vehicles,
    this.suggestedRouteId,
    this.suggestedVehicleId,
  });

  factory TripChoices.fromJson(Map<String, dynamic> json) {
    final routes = json['routes'] as List<dynamic>;
    final vehicles = json['vehicles'] as List<dynamic>;
    final suggested = json['suggested'] as Map<String, dynamic>;

    return TripChoices(
      routes: routes
          .map((item) => RouteChoice.fromJson(item as Map<String, dynamic>))
          .toList(),
      vehicles: vehicles
          .map((item) => VehicleChoice.fromJson(item as Map<String, dynamic>))
          .toList(),
      suggestedRouteId: suggested['route_id'] as int?,
      suggestedVehicleId: suggested['vehicle_id'] as int?,
    );
  }

  final List<RouteChoice> routes;
  final List<VehicleChoice> vehicles;

  // the way back from the conductor's last trip, on the same vehicle if it's free
  final int? suggestedRouteId;
  final int? suggestedVehicleId;

  RouteChoice? get suggestedRoute => routes.where((route) => route.id == suggestedRouteId).firstOrNull;

  VehicleChoice? get suggestedVehicle => vehicles.where((vehicle) => vehicle.id == suggestedVehicleId).firstOrNull;
}