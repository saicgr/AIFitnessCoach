// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gym_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GymLocation _$GymLocationFromJson(Map<String, dynamic> json) => GymLocation(
  placeId: json['place_id'] as String?,
  name: json['name'] as String,
  address: json['address'] as String,
  city: json['city'] as String?,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
);

Map<String, dynamic> _$GymLocationToJson(GymLocation instance) =>
    <String, dynamic>{
      'place_id': instance.placeId,
      'name': instance.name,
      'address': instance.address,
      'city': instance.city,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'distance_meters': instance.distanceMeters,
    };

PlacePrediction _$PlacePredictionFromJson(Map<String, dynamic> json) =>
    PlacePrediction(
      placeId: json['place_id'] as String,
      mainText: json['main_text'] as String,
      secondaryText: json['secondary_text'] as String,
      description: json['description'] as String,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PlacePredictionToJson(PlacePrediction instance) =>
    <String, dynamic>{
      'place_id': instance.placeId,
      'main_text': instance.mainText,
      'secondary_text': instance.secondaryText,
      'description': instance.description,
      'distance_meters': instance.distanceMeters,
    };
