/// Mirrors eventsrus-backend's `com.backend.eventsrus.enums.EventType`
/// exactly (same names) — used for a vendor's `cateredEventTypes` on the
/// Account Settings "Service Scope" tab. Not to be confused with
/// `PlannerEventType`, a different (smaller) enum used for planner-side
/// event creation.
enum VendorEventType {
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

extension VendorEventTypeApi on VendorEventType {
  String toApi() {
    switch (this) {
      case VendorEventType.wedding:
        return 'WEDDING';
      case VendorEventType.anniversary:
        return 'ANNIVERSARY';
      case VendorEventType.birthday:
        return 'BIRTHDAY';
      case VendorEventType.debut:
        return 'DEBUT';
      case VendorEventType.party:
        return 'PARTY';
      case VendorEventType.babyShower:
        return 'BABY_SHOWER';
      case VendorEventType.bridalShower:
        return 'BRIDAL_SHOWER';
      case VendorEventType.bachelorParty:
        return 'BACHELOR_PARTY';
      case VendorEventType.bacheloretteParty:
        return 'BACHELORETTE_PARTY';
      case VendorEventType.engagementParty:
        return 'ENGAGEMENT_PARTY';
      case VendorEventType.graduation:
        return 'GRADUATION';
      case VendorEventType.retirement:
        return 'RETIREMENT';
      case VendorEventType.reunion:
        return 'REUNION';
      case VendorEventType.housewarming:
        return 'HOUSEWARMING';
      case VendorEventType.seminar:
        return 'SEMINAR';
      case VendorEventType.networkingEvent:
        return 'NETWORKING_EVENT';
      case VendorEventType.corporateEvent:
        return 'CORPORATE_EVENT';
      case VendorEventType.productLaunch:
        return 'PRODUCT_LAUNCH';
      case VendorEventType.teamBuilding:
        return 'TEAM_BUILDING';
      case VendorEventType.corporateRetreat:
        return 'CORPORATE_RETREAT';
      case VendorEventType.tradeShow:
        return 'TRADE_SHOW';
      case VendorEventType.gala:
        return 'GALA';
      case VendorEventType.fundraiser:
        return 'FUNDRAISER';
      case VendorEventType.concert:
        return 'CONCERT';
      case VendorEventType.festival:
        return 'FESTIVAL';
      case VendorEventType.exhibition:
        return 'EXHIBITION';
      case VendorEventType.sportsEvent:
        return 'SPORTS_EVENT';
      case VendorEventType.other:
        return 'OTHER';
    }
  }

  String get label {
    switch (this) {
      case VendorEventType.wedding:
        return 'Wedding';
      case VendorEventType.anniversary:
        return 'Anniversary';
      case VendorEventType.birthday:
        return 'Birthday';
      case VendorEventType.debut:
        return 'Debut';
      case VendorEventType.party:
        return 'Party';
      case VendorEventType.babyShower:
        return 'Baby Shower';
      case VendorEventType.bridalShower:
        return 'Bridal Shower';
      case VendorEventType.bachelorParty:
        return 'Bachelor Party';
      case VendorEventType.bacheloretteParty:
        return 'Bachelorette Party';
      case VendorEventType.engagementParty:
        return 'Engagement Party';
      case VendorEventType.graduation:
        return 'Graduation';
      case VendorEventType.retirement:
        return 'Retirement';
      case VendorEventType.reunion:
        return 'Reunion';
      case VendorEventType.housewarming:
        return 'Housewarming';
      case VendorEventType.seminar:
        return 'Seminar';
      case VendorEventType.networkingEvent:
        return 'Networking Event';
      case VendorEventType.corporateEvent:
        return 'Corporate Event';
      case VendorEventType.productLaunch:
        return 'Product Launch';
      case VendorEventType.teamBuilding:
        return 'Team Building';
      case VendorEventType.corporateRetreat:
        return 'Corporate Retreat';
      case VendorEventType.tradeShow:
        return 'Trade Show';
      case VendorEventType.gala:
        return 'Gala';
      case VendorEventType.fundraiser:
        return 'Fundraiser';
      case VendorEventType.concert:
        return 'Concert';
      case VendorEventType.festival:
        return 'Festival';
      case VendorEventType.exhibition:
        return 'Exhibition';
      case VendorEventType.sportsEvent:
        return 'Sports Event';
      case VendorEventType.other:
        return 'Other';
    }
  }

  static VendorEventType fromApi(String value) {
    switch (value) {
      case 'WEDDING':
        return VendorEventType.wedding;
      case 'ANNIVERSARY':
        return VendorEventType.anniversary;
      case 'BIRTHDAY':
        return VendorEventType.birthday;
      case 'DEBUT':
        return VendorEventType.debut;
      case 'PARTY':
        return VendorEventType.party;
      case 'BABY_SHOWER':
        return VendorEventType.babyShower;
      case 'BRIDAL_SHOWER':
        return VendorEventType.bridalShower;
      case 'BACHELOR_PARTY':
        return VendorEventType.bachelorParty;
      case 'BACHELORETTE_PARTY':
        return VendorEventType.bacheloretteParty;
      case 'ENGAGEMENT_PARTY':
        return VendorEventType.engagementParty;
      case 'GRADUATION':
        return VendorEventType.graduation;
      case 'RETIREMENT':
        return VendorEventType.retirement;
      case 'REUNION':
        return VendorEventType.reunion;
      case 'HOUSEWARMING':
        return VendorEventType.housewarming;
      case 'SEMINAR':
        return VendorEventType.seminar;
      case 'NETWORKING_EVENT':
        return VendorEventType.networkingEvent;
      case 'CORPORATE_EVENT':
        return VendorEventType.corporateEvent;
      case 'PRODUCT_LAUNCH':
        return VendorEventType.productLaunch;
      case 'TEAM_BUILDING':
        return VendorEventType.teamBuilding;
      case 'CORPORATE_RETREAT':
        return VendorEventType.corporateRetreat;
      case 'TRADE_SHOW':
        return VendorEventType.tradeShow;
      case 'GALA':
        return VendorEventType.gala;
      case 'FUNDRAISER':
        return VendorEventType.fundraiser;
      case 'CONCERT':
        return VendorEventType.concert;
      case 'FESTIVAL':
        return VendorEventType.festival;
      case 'EXHIBITION':
        return VendorEventType.exhibition;
      case 'SPORTS_EVENT':
        return VendorEventType.sportsEvent;
      case 'OTHER':
        return VendorEventType.other;
      default:
        return VendorEventType.other;
    }
  }
}
