/// Mirrors eventsrus-backend's enums.BusinessType exactly (same names), so
/// the value submitted here needs no translation once posted to the real
/// backend.
enum BusinessType {
  venue,
  catering,
  photoAndVideo,
  photoBooths,
  eventCoordinator,
  eventHost,
  entertainment,
  performers,
  decorationProduction,
  lightsAndSounds,
  foodCartsGrazing,
  souvenirGiveaways,
  cakeAndPastries,
  inflatables,
  mobilePlayground,
  arcade,
  invitations,
  hairAndMakeup,
  bridalGownDesigner,
  suitRentals,
  wardrobeStylistsDressers,
  powerGeneratorServices,
  ledWallVisualProjectionRentals,
  stagingTrussingFlooringRentals,
  transportShuttleFleetServices,
  securityCrowdControl,
  interactiveBarMixologyServices,
  liveEventPaintersSketchArtists,
  specialEffects,
  floralServices,
}

extension BusinessTypeApi on BusinessType {
  String toApi() {
    switch (this) {
      case BusinessType.venue:
        return 'VENUE';
      case BusinessType.catering:
        return 'CATERING';
      case BusinessType.photoAndVideo:
        return 'PHOTO_AND_VIDEO';
      case BusinessType.photoBooths:
        return 'PHOTO_BOOTHS';
      case BusinessType.eventCoordinator:
        return 'EVENT_COORDINATOR';
      case BusinessType.eventHost:
        return 'EVENT_HOST';
      case BusinessType.entertainment:
        return 'ENTERTAINMENT';
      case BusinessType.performers:
        return 'PERFORMERS';
      case BusinessType.decorationProduction:
        return 'DECORATION_PRODUCTION';
      case BusinessType.lightsAndSounds:
        return 'LIGHTS_AND_SOUNDS';
      case BusinessType.foodCartsGrazing:
        return 'FOOD_CARTS_GRAZING';
      case BusinessType.souvenirGiveaways:
        return 'SOUVENIR_GIVEAWAYS';
      case BusinessType.cakeAndPastries:
        return 'CAKE_AND_PASTRIES';
      case BusinessType.inflatables:
        return 'INFLATABLES';
      case BusinessType.mobilePlayground:
        return 'MOBILE_PLAYGROUND';
      case BusinessType.arcade:
        return 'ARCADE';
      case BusinessType.invitations:
        return 'INVITATIONS';
      case BusinessType.hairAndMakeup:
        return 'HAIR_AND_MAKEUP';
      case BusinessType.bridalGownDesigner:
        return 'BRIDAL_GOWN_DESIGNER';
      case BusinessType.suitRentals:
        return 'SUIT_RENTALS';
      case BusinessType.wardrobeStylistsDressers:
        return 'WARDROBE_STYLISTS_DRESSERS';
      case BusinessType.powerGeneratorServices:
        return 'POWER_GENERATOR_SERVICES';
      case BusinessType.ledWallVisualProjectionRentals:
        return 'LED_WALL_VISUAL_PROJECTION_RENTALS';
      case BusinessType.stagingTrussingFlooringRentals:
        return 'STAGING_TRUSSING_FLOORING_RENTALS';
      case BusinessType.transportShuttleFleetServices:
        return 'TRANSPORT_SHUTTLE_FLEET_SERVICES';
      case BusinessType.securityCrowdControl:
        return 'SECURITY_CROWD_CONTROL';
      case BusinessType.interactiveBarMixologyServices:
        return 'INTERACTIVE_BAR_MIXOLOGY_SERVICES';
      case BusinessType.liveEventPaintersSketchArtists:
        return 'LIVE_EVENT_PAINTERS_SKETCH_ARTISTS';
      case BusinessType.specialEffects:
        return 'SPECIAL_EFFECTS';
      case BusinessType.floralServices:
        return 'FLORAL_SERVICES';
    }
  }

  String get label {
    switch (this) {
      case BusinessType.venue:
        return 'Venue';
      case BusinessType.catering:
        return 'Catering';
      case BusinessType.photoAndVideo:
        return 'Photo and Video';
      case BusinessType.photoBooths:
        return 'Photo Booths';
      case BusinessType.eventCoordinator:
        return 'Event Coordinator';
      case BusinessType.eventHost:
        return 'Event Host';
      case BusinessType.entertainment:
        return 'Entertainment';
      case BusinessType.performers:
        return 'Performers';
      case BusinessType.decorationProduction:
        return 'Decoration/Production';
      case BusinessType.lightsAndSounds:
        return 'Lights and Sounds';
      case BusinessType.foodCartsGrazing:
        return 'Food carts/Grazing';
      case BusinessType.souvenirGiveaways:
        return 'Souvenir/Give Aways';
      case BusinessType.cakeAndPastries:
        return 'Cake and Pastries';
      case BusinessType.inflatables:
        return 'Inflatables';
      case BusinessType.mobilePlayground:
        return 'Mobile Playground';
      case BusinessType.arcade:
        return 'Arcade';
      case BusinessType.invitations:
        return 'Invitations';
      case BusinessType.hairAndMakeup:
        return 'Hair and Makeup';
      case BusinessType.bridalGownDesigner:
        return 'Bridal Gown Designer';
      case BusinessType.suitRentals:
        return 'Suit Rentals';
      case BusinessType.wardrobeStylistsDressers:
        return 'Wardrobe Stylists & Dressers';
      case BusinessType.powerGeneratorServices:
        return 'Power & Generator Services';
      case BusinessType.ledWallVisualProjectionRentals:
        return 'LED Wall & Visual Projection Rentals';
      case BusinessType.stagingTrussingFlooringRentals:
        return 'Staging, Trussing, & Flooring Rentals';
      case BusinessType.transportShuttleFleetServices:
        return 'Transport, Shuttle, & Fleet Services';
      case BusinessType.securityCrowdControl:
        return 'Security & Crowd Control';
      case BusinessType.interactiveBarMixologyServices:
        return 'Interactive Bar & Mixology Services';
      case BusinessType.liveEventPaintersSketchArtists:
        return 'Live Event Painters & Sketch Artists';
      case BusinessType.specialEffects:
        return 'Special Effects';
      case BusinessType.floralServices:
        return 'Floral Services';
    }
  }

  static BusinessType fromApi(String value) {
    switch (value) {
      case 'VENUE':
        return BusinessType.venue;
      case 'CATERING':
        return BusinessType.catering;
      case 'PHOTO_AND_VIDEO':
        return BusinessType.photoAndVideo;
      case 'PHOTO_BOOTHS':
        return BusinessType.photoBooths;
      case 'EVENT_COORDINATOR':
        return BusinessType.eventCoordinator;
      case 'EVENT_HOST':
        return BusinessType.eventHost;
      case 'ENTERTAINMENT':
        return BusinessType.entertainment;
      case 'PERFORMERS':
        return BusinessType.performers;
      case 'DECORATION_PRODUCTION':
        return BusinessType.decorationProduction;
      case 'LIGHTS_AND_SOUNDS':
        return BusinessType.lightsAndSounds;
      case 'FOOD_CARTS_GRAZING':
        return BusinessType.foodCartsGrazing;
      case 'SOUVENIR_GIVEAWAYS':
        return BusinessType.souvenirGiveaways;
      case 'CAKE_AND_PASTRIES':
        return BusinessType.cakeAndPastries;
      case 'INFLATABLES':
        return BusinessType.inflatables;
      case 'MOBILE_PLAYGROUND':
        return BusinessType.mobilePlayground;
      case 'ARCADE':
        return BusinessType.arcade;
      case 'INVITATIONS':
        return BusinessType.invitations;
      case 'HAIR_AND_MAKEUP':
        return BusinessType.hairAndMakeup;
      case 'BRIDAL_GOWN_DESIGNER':
        return BusinessType.bridalGownDesigner;
      case 'SUIT_RENTALS':
        return BusinessType.suitRentals;
      case 'WARDROBE_STYLISTS_DRESSERS':
        return BusinessType.wardrobeStylistsDressers;
      case 'POWER_GENERATOR_SERVICES':
        return BusinessType.powerGeneratorServices;
      case 'LED_WALL_VISUAL_PROJECTION_RENTALS':
        return BusinessType.ledWallVisualProjectionRentals;
      case 'STAGING_TRUSSING_FLOORING_RENTALS':
        return BusinessType.stagingTrussingFlooringRentals;
      case 'TRANSPORT_SHUTTLE_FLEET_SERVICES':
        return BusinessType.transportShuttleFleetServices;
      case 'SECURITY_CROWD_CONTROL':
        return BusinessType.securityCrowdControl;
      case 'INTERACTIVE_BAR_MIXOLOGY_SERVICES':
        return BusinessType.interactiveBarMixologyServices;
      case 'LIVE_EVENT_PAINTERS_SKETCH_ARTISTS':
        return BusinessType.liveEventPaintersSketchArtists;
      case 'SPECIAL_EFFECTS':
        return BusinessType.specialEffects;
      case 'FLORAL_SERVICES':
        return BusinessType.floralServices;
      default:
        throw FormatException('Unknown business type: $value');
    }
  }
}
