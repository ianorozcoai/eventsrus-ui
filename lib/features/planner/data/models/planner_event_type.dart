/// Mirrors eventsrus-backend's {@code com.backend.eventsrus.enums.EventType}
/// field-for-field. Previously only had 5 of the real 28 values (wedding/
/// anniversary/birthday/party/other), silently collapsing every other real
/// type (e.g. an event created via eventsrus-web as "Graduation") into
/// "Other" on round-trip - event_create_screen.dart's picker can still
/// offer whatever curated subset makes sense for quick creation, but
/// parsing/display elsewhere (e.g. Quotation.eventType) must be able to
/// represent every value the backend can actually send.
enum PlannerEventType {
  wedding,
  anniversary,
  birthday,
  debut,
  party,
  babyShower,
  bridalShower,
  bachelorParty,
  bacheloretteParty,
  engagementParty,
  graduation,
  retirement,
  reunion,
  housewarming,
  seminar,
  networkingEvent,
  corporateEvent,
  productLaunch,
  teamBuilding,
  corporateRetreat,
  tradeShow,
  gala,
  fundraiser,
  concert,
  festival,
  exhibition,
  sportsEvent,
  other,
}

extension PlannerEventTypeApi on PlannerEventType {
  String toApi() {
    switch (this) {
      case PlannerEventType.wedding:
        return 'WEDDING';
      case PlannerEventType.anniversary:
        return 'ANNIVERSARY';
      case PlannerEventType.birthday:
        return 'BIRTHDAY';
      case PlannerEventType.debut:
        return 'DEBUT';
      case PlannerEventType.party:
        return 'PARTY';
      case PlannerEventType.babyShower:
        return 'BABY_SHOWER';
      case PlannerEventType.bridalShower:
        return 'BRIDAL_SHOWER';
      case PlannerEventType.bachelorParty:
        return 'BACHELOR_PARTY';
      case PlannerEventType.bacheloretteParty:
        return 'BACHELORETTE_PARTY';
      case PlannerEventType.engagementParty:
        return 'ENGAGEMENT_PARTY';
      case PlannerEventType.graduation:
        return 'GRADUATION';
      case PlannerEventType.retirement:
        return 'RETIREMENT';
      case PlannerEventType.reunion:
        return 'REUNION';
      case PlannerEventType.housewarming:
        return 'HOUSEWARMING';
      case PlannerEventType.seminar:
        return 'SEMINAR';
      case PlannerEventType.networkingEvent:
        return 'NETWORKING_EVENT';
      case PlannerEventType.corporateEvent:
        return 'CORPORATE_EVENT';
      case PlannerEventType.productLaunch:
        return 'PRODUCT_LAUNCH';
      case PlannerEventType.teamBuilding:
        return 'TEAM_BUILDING';
      case PlannerEventType.corporateRetreat:
        return 'CORPORATE_RETREAT';
      case PlannerEventType.tradeShow:
        return 'TRADE_SHOW';
      case PlannerEventType.gala:
        return 'GALA';
      case PlannerEventType.fundraiser:
        return 'FUNDRAISER';
      case PlannerEventType.concert:
        return 'CONCERT';
      case PlannerEventType.festival:
        return 'FESTIVAL';
      case PlannerEventType.exhibition:
        return 'EXHIBITION';
      case PlannerEventType.sportsEvent:
        return 'SPORTS_EVENT';
      case PlannerEventType.other:
        return 'OTHER';
    }
  }

  String get label {
    switch (this) {
      case PlannerEventType.wedding:
        return 'Wedding';
      case PlannerEventType.anniversary:
        return 'Anniversary';
      case PlannerEventType.birthday:
        return 'Birthday';
      case PlannerEventType.debut:
        return 'Debut';
      case PlannerEventType.party:
        return 'Party';
      case PlannerEventType.babyShower:
        return 'Baby Shower';
      case PlannerEventType.bridalShower:
        return 'Bridal Shower';
      case PlannerEventType.bachelorParty:
        return 'Bachelor Party';
      case PlannerEventType.bacheloretteParty:
        return 'Bachelorette Party';
      case PlannerEventType.engagementParty:
        return 'Engagement Party';
      case PlannerEventType.graduation:
        return 'Graduation';
      case PlannerEventType.retirement:
        return 'Retirement';
      case PlannerEventType.reunion:
        return 'Reunion';
      case PlannerEventType.housewarming:
        return 'Housewarming';
      case PlannerEventType.seminar:
        return 'Seminar';
      case PlannerEventType.networkingEvent:
        return 'Networking Event';
      case PlannerEventType.corporateEvent:
        return 'Corporate Event';
      case PlannerEventType.productLaunch:
        return 'Product Launch';
      case PlannerEventType.teamBuilding:
        return 'Team Building';
      case PlannerEventType.corporateRetreat:
        return 'Corporate Retreat';
      case PlannerEventType.tradeShow:
        return 'Trade Show';
      case PlannerEventType.gala:
        return 'Gala';
      case PlannerEventType.fundraiser:
        return 'Fundraiser';
      case PlannerEventType.concert:
        return 'Concert';
      case PlannerEventType.festival:
        return 'Festival';
      case PlannerEventType.exhibition:
        return 'Exhibition';
      case PlannerEventType.sportsEvent:
        return 'Sports Event';
      case PlannerEventType.other:
        return 'Other';
    }
  }

  static PlannerEventType fromApi(String value) {
    switch (value) {
      case 'WEDDING':
        return PlannerEventType.wedding;
      case 'ANNIVERSARY':
        return PlannerEventType.anniversary;
      case 'BIRTHDAY':
        return PlannerEventType.birthday;
      case 'DEBUT':
        return PlannerEventType.debut;
      case 'PARTY':
        return PlannerEventType.party;
      case 'BABY_SHOWER':
        return PlannerEventType.babyShower;
      case 'BRIDAL_SHOWER':
        return PlannerEventType.bridalShower;
      case 'BACHELOR_PARTY':
        return PlannerEventType.bachelorParty;
      case 'BACHELORETTE_PARTY':
        return PlannerEventType.bacheloretteParty;
      case 'ENGAGEMENT_PARTY':
        return PlannerEventType.engagementParty;
      case 'GRADUATION':
        return PlannerEventType.graduation;
      case 'RETIREMENT':
        return PlannerEventType.retirement;
      case 'REUNION':
        return PlannerEventType.reunion;
      case 'HOUSEWARMING':
        return PlannerEventType.housewarming;
      case 'SEMINAR':
        return PlannerEventType.seminar;
      case 'NETWORKING_EVENT':
        return PlannerEventType.networkingEvent;
      case 'CORPORATE_EVENT':
        return PlannerEventType.corporateEvent;
      case 'PRODUCT_LAUNCH':
        return PlannerEventType.productLaunch;
      case 'TEAM_BUILDING':
        return PlannerEventType.teamBuilding;
      case 'CORPORATE_RETREAT':
        return PlannerEventType.corporateRetreat;
      case 'TRADE_SHOW':
        return PlannerEventType.tradeShow;
      case 'GALA':
        return PlannerEventType.gala;
      case 'FUNDRAISER':
        return PlannerEventType.fundraiser;
      case 'CONCERT':
        return PlannerEventType.concert;
      case 'FESTIVAL':
        return PlannerEventType.festival;
      case 'EXHIBITION':
        return PlannerEventType.exhibition;
      case 'SPORTS_EVENT':
        return PlannerEventType.sportsEvent;
      default:
        // "OTHER" and any future backend value this build doesn't know
        // about yet both land here - safe forward-compatible fallback.
        return PlannerEventType.other;
    }
  }
}
