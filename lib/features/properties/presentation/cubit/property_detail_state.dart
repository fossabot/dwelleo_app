import '../../domain/entities/property.dart';

sealed class PropertyDetailState {
  const PropertyDetailState();
}

class PropertyDetailInitial extends PropertyDetailState {
  const PropertyDetailInitial();
}

class PropertyDetailLoading extends PropertyDetailState {
  const PropertyDetailLoading();
}

class PropertyDetailLoaded extends PropertyDetailState {
  final Property property;
  const PropertyDetailLoaded(this.property);
}

class PropertyDetailError extends PropertyDetailState {
  final String message;
  const PropertyDetailError(this.message);
}
